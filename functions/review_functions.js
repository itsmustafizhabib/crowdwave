const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Cloud Function to automatically update review summaries when reviews are created/updated
exports.updateReviewSummary = functions.firestore
  .document('reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const reviewId = context.params.reviewId;
    
    try {
      // Get the review data
      const reviewData = change.after.exists ? change.after.data() : null;
      const oldReviewData = change.before.exists ? change.before.data() : null;
      
      if (!reviewData && !oldReviewData) {
        return null; // Nothing to process
      }
      
      const targetId = reviewData?.targetId || oldReviewData?.targetId;
      
      if (!targetId) {
        console.error('No targetId found in review data');
        return null;
      }
      
      // Get all approved reviews for this target
      const reviewsSnapshot = await db.collection('reviews')
        .where('targetId', '==', targetId)
        .where('moderationStatus', '==', 'approved')
        .get();
      
      let totalReviews = 0;
      let totalRating = 0;
      let verifiedReviewsCount = 0;
      const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
      
      reviewsSnapshot.forEach(doc => {
        const review = doc.data();
        totalReviews++;
        totalRating += review.rating;
        
        if (review.isVerifiedBooking) {
          verifiedReviewsCount++;
        }
        
        const starRating = Math.round(review.rating);
        if (ratingDistribution[starRating] !== undefined) {
          ratingDistribution[starRating]++;
        }
      });
      
      const averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;
      
      const summaryData = {
        averageRating,
        totalReviews,
        ratingDistribution,
        verifiedReviewsCount,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      // Update or create the review summary
      await db.collection('review_summaries').doc(targetId).set(summaryData, { merge: true });
      
      console.log(`Updated review summary for ${targetId}: ${totalReviews} reviews, ${averageRating.toFixed(1)} average`);
      
      return null;
    } catch (error) {
      console.error('Error updating review summary:', error);
      return null;
    }
  });

// Cloud Function for content moderation
exports.moderateReviewContent = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const reviewId = context.params.reviewId;
    const reviewData = snap.data();
    
    try {
      let moderationStatus = 'approved'; // Default to approved
      let flaggedReasons = [];
      
      // Basic content moderation
      if (reviewData.comment) {
        const content = reviewData.comment.toLowerCase();
        
        // Check for profanity (basic implementation)
        const profanityWords = ['spam', 'fake', 'scam', 'terrible', 'awful'];
        const containsProfanity = profanityWords.some(word => content.includes(word));
        
        if (containsProfanity) {
          moderationStatus = 'flagged';
          flaggedReasons.push('Contains potentially inappropriate language');
        }
        
        // Check for spam patterns
        const spamPatterns = [
          /\b(?:buy|visit|click|check)\s+(?:here|now|this)\b/i,
          /\b(?:www\.|http|\.com|\.net|\.org)\b/i,
          /\b(?:free|win|winner|prize|cash|money)\b.*\b(?:now|today|urgent)\b/i,
        ];
        
        const containsSpam = spamPatterns.some(pattern => pattern.test(content));
        
        if (containsSpam) {
          moderationStatus = 'flagged';
          flaggedReasons.push('Contains spam-like content');
        }
        
        // Check content length
        if (content.trim().length < 10) {
          moderationStatus = 'pending';
          flaggedReasons.push('Content too short');
        }
        
        // Check for excessive caps
        const capsCount = content.replace(/[^A-Z]/g, '').length;
        if (capsCount > content.length * 0.7) {
          moderationStatus = 'pending';
          flaggedReasons.push('Excessive capitalization');
        }
      }
      
      // Update the review with moderation status
      const updateData = {
        moderationStatus,
        moderationTimestamp: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      if (flaggedReasons.length > 0) {
        updateData.flaggedReasons = flaggedReasons;
      }
      
      await snap.ref.update(updateData);
      
      console.log(`Moderated review ${reviewId}: ${moderationStatus}`);
      
      // If flagged, create a moderation alert
      if (moderationStatus === 'flagged') {
        await db.collection('moderation_alerts').add({
          reviewId,
          type: 'auto_flagged',
          reasons: flaggedReasons,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          status: 'pending',
        });
      }
      
      return null;
    } catch (error) {
      console.error('Error moderating review content:', error);
      return null;
    }
  });

// Cloud Function to handle report submissions
exports.processReportSubmission = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const reportId = context.params.reportId;
    const reportData = snap.data();
    
    try {
      // Increment report count for the review
      const reviewRef = db.collection('reviews').doc(reportData.reviewId);
      await reviewRef.update({
        reportCount: admin.firestore.FieldValue.increment(1),
      });
      
      // If too many reports, auto-flag the review
      const reviewDoc = await reviewRef.get();
      const reviewData = reviewDoc.data();
      
      if (reviewData && reviewData.reportCount >= 3) {
        await reviewRef.update({
          moderationStatus: 'flagged',
          autoFlaggedReason: 'Multiple user reports',
          moderationTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        // Create moderation alert
        await db.collection('moderation_alerts').add({
          reviewId: reportData.reviewId,
          type: 'multiple_reports',
          reportCount: reviewData.reportCount,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          status: 'pending',
        });
      }
      
      console.log(`Processed report ${reportId} for review ${reportData.reviewId}`);
      
      return null;
    } catch (error) {
      console.error('Error processing report:', error);
      return null;
    }
  });

// Cloud Function to send notifications for new reviews
exports.notifyOnNewReview = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const reviewData = snap.data();
    
    try {
      // Get the target (trip or package) to find who should be notified
      let targetDoc;
      let targetOwnerField;
      
      if (reviewData.type === 'trip') {
        targetDoc = await db.collection('trips').doc(reviewData.targetId).get();
        targetOwnerField = 'travelerId';
      } else if (reviewData.type === 'package') {
        targetDoc = await db.collection('packageRequests').doc(reviewData.targetId).get();
        targetOwnerField = 'senderId';
      }
      
      if (!targetDoc || !targetDoc.exists) {
        console.log('Target not found for review notification');
        return null;
      }
      
      const targetData = targetDoc.data();
      const targetOwnerId = targetData[targetOwnerField];
      
      // Don't notify if the reviewer is the same as the target owner
      if (targetOwnerId === reviewData.reviewerId) {
        return null;
      }
      
      // Create notification
      await db.collection('notifications').add({
        userId: targetOwnerId,
        type: 'new_review',
        title: 'New Review Received',
        message: `${reviewData.reviewerName} left you a ${reviewData.rating}-star review`,
        data: {
          reviewId: context.params.reviewId,
          targetId: reviewData.targetId,
          targetType: reviewData.type,
          rating: reviewData.rating,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
      
      console.log(`Created notification for new review to user ${targetOwnerId}`);
      
      return null;
    } catch (error) {
      console.error('Error sending review notification:', error);
      return null;
    }
  });

// Scheduled function to clean up old flagged reviews
exports.cleanupFlaggedReviews = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      // Find old flagged reviews that haven't been resolved
      const flaggedReviewsSnapshot = await db.collection('reviews')
        .where('moderationStatus', '==', 'flagged')
        .where('moderationTimestamp', '<', thirtyDaysAgo)
        .get();
      
      const batch = db.batch();
      let count = 0;
      
      flaggedReviewsSnapshot.forEach(doc => {
        // Auto-reject old flagged reviews
        batch.update(doc.ref, {
          moderationStatus: 'rejected',
          autoRejectedReason: 'Flagged for over 30 days without manual review',
          moderationTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        count++;
      });
      
      if (count > 0) {
        await batch.commit();
      }
      
      console.log(`Cleaned up ${count} old flagged reviews`);
      
      return null;
    } catch (error) {
      console.error('Error cleaning up flagged reviews:', error);
      return null;
    }
  });

// Function to generate review analytics
exports.generateReviewAnalytics = functions.https.onRequest(async (req, res) => {
  try {
    // This would be protected by authentication in a real app
    
    const reviewsSnapshot = await db.collection('reviews')
      .where('moderationStatus', '==', 'approved')
      .get();
    
    let totalReviews = 0;
    let totalRating = 0;
    let verifiedReviews = 0;
    const typeDistribution = {};
    const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    
    reviewsSnapshot.forEach(doc => {
      const review = doc.data();
      totalReviews++;
      totalRating += review.rating;
      
      if (review.isVerifiedBooking) {
        verifiedReviews++;
      }
      
      // Type distribution
      typeDistribution[review.type] = (typeDistribution[review.type] || 0) + 1;
      
      // Rating distribution
      const starRating = Math.round(review.rating);
      if (ratingDistribution[starRating] !== undefined) {
        ratingDistribution[starRating]++;
      }
    });
    
    const analytics = {
      totalReviews,
      averageRating: totalReviews > 0 ? totalRating / totalReviews : 0,
      verifiedReviews,
      verificationRate: totalReviews > 0 ? (verifiedReviews / totalReviews) * 100 : 0,
      typeDistribution,
      ratingDistribution,
      generatedAt: new Date().toISOString(),
    };
    
    res.json(analytics);
  } catch (error) {
    console.error('Error generating analytics:', error);
    res.status(500).json({ error: 'Failed to generate analytics' });
  }
});
