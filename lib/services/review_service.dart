import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../services/image_storage_service.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageStorageService _imageStorage = ImageStorageService();

  // Collections
  CollectionReference get _reviewsCollection =>
      _firestore.collection('reviews');
  CollectionReference get _reviewSummariesCollection =>
      _firestore.collection('review_summaries');

  // Create a new review
  Future<String> createReview({
    required String reviewerId,
    required String reviewerName,
    String? reviewerAvatar,
    required String targetId,
    required ReviewType type,
    required double rating,
    String? comment,
    List<File>? photos,
    bool isVerifiedBooking = false,
  }) async {
    try {
      // Generate review ID
      final reviewId = _reviewsCollection.doc().id;

      // Convert photos to base64 if provided (cost-effective approach)
      // ✅ COST SAVING: Using base64 storage in Firestore instead of Firebase Storage
      // This avoids storage costs + bandwidth charges for each image view
      List<String>? photoBase64List;
      if (photos != null && photos.isNotEmpty) {
        photoBase64List = await _convertPhotosToBase64(photos);
      }

      // Create review object
      final review = Review(
        id: reviewId,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        reviewerAvatar: reviewerAvatar,
        targetId: targetId,
        type: type,
        rating: rating,
        comment: comment,
        photoUrls: photoBase64List, // Store base64 strings instead of URLs
        createdAt: DateTime.now(),
        moderationStatus: ModerationStatus.approved, // Auto-approve for now
        isVerifiedBooking: isVerifiedBooking,
      );

      // Save to Firestore
      await _reviewsCollection.doc(reviewId).set(review.toJson());

      // Update review summary
      await _updateReviewSummary(targetId, rating, 1);

      return reviewId;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Get reviews for a specific target (trip/package)
  Future<List<Review>> getReviews({
    required String targetId,
    ReviewFilter? filter,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _reviewsCollection
          .where('targetId', isEqualTo: targetId)
          .where('moderationStatus', isEqualTo: 'approved');

      // Apply filters
      if (filter != null) {
        if (filter.starRatings != null && filter.starRatings!.isNotEmpty) {
          query = query.where('rating',
              whereIn: filter.starRatings!.map((r) => r.toDouble()).toList());
        }

        if (filter.verifiedOnly == true) {
          query = query.where('isVerifiedBooking', isEqualTo: true);
        }

        if (filter.withPhotos == true) {
          query = query.where('photoUrls', isNull: false);
        }

        if (filter.withComments == true) {
          query = query.where('comment', isNull: false);
        }
      }

      // Apply sorting
      String orderField = 'createdAt';
      bool descending = true;

      if (filter?.sortBy != null) {
        switch (filter!.sortBy) {
          case ReviewSortBy.newest:
            orderField = 'createdAt';
            descending = true;
            break;
          case ReviewSortBy.oldest:
            orderField = 'createdAt';
            descending = false;
            break;
          case ReviewSortBy.highestRated:
            orderField = 'rating';
            descending = true;
            break;
          case ReviewSortBy.lowestRated:
            orderField = 'rating';
            descending = false;
            break;
          case ReviewSortBy.mostHelpful:
            orderField = 'helpfulCount';
            descending = true;
            break;
        }
      }

      query = query.orderBy(orderField, descending: descending);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Review.fromJson(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  // Get review summary for a target
  Future<ReviewSummary> getReviewSummary(String targetId) async {
    try {
      final doc = await _reviewSummariesCollection.doc(targetId).get();

      if (doc.exists) {
        return ReviewSummary.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        // Create empty summary
        return ReviewSummary(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
          verifiedReviewsCount: 0,
        );
      }
    } catch (e) {
      throw Exception('Failed to get review summary: $e');
    }
  }

  // Get a single review by ID
  Future<Review?> getReviewById(String reviewId) async {
    try {
      final doc = await _reviewsCollection.doc(reviewId).get();

      if (doc.exists) {
        return Review.fromJson(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get review: $e');
    }
  }

  // Add comment to a review
  Future<String> addComment({
    required String reviewId,
    required String commenterId,
    required String commenterName,
    String? commenterAvatar,
    required String content,
    String? replyToId, // For nested replies
  }) async {
    try {
      final commentId = _firestore.collection('temp').doc().id;

      final comment = ReviewComment(
        id: commentId,
        commenterId: commenterId,
        commenterName: commenterName,
        commenterAvatar: commenterAvatar,
        content: content,
        createdAt: DateTime.now(),
        moderationStatus: ModerationStatus.approved, // Auto-approve for now
        replyToId: replyToId,
      );

      // Get the review
      final reviewDoc = await _reviewsCollection.doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }

      final review = Review.fromJson(
          {...reviewDoc.data() as Map<String, dynamic>, 'id': reviewDoc.id});
      List<ReviewComment> updatedComments = List.from(review.comments);

      if (replyToId != null) {
        // This is a reply to an existing comment
        for (int i = 0; i < updatedComments.length; i++) {
          if (updatedComments[i].id == replyToId) {
            // Add reply to the parent comment
            List<ReviewComment> replies = List.from(updatedComments[i].replies);
            replies.add(comment);
            updatedComments[i] = updatedComments[i].copyWith(replies: replies);
            break;
          }
        }
      } else {
        // This is a top-level comment
        updatedComments.add(comment);
      }

      // Update the review with new comments
      await _reviewsCollection.doc(reviewId).update({
        'comments': updatedComments.map((c) => c.toJson()).toList(),
      });

      return commentId;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Mark review as helpful
  Future<void> markReviewHelpful(
      String reviewId, String userId, bool helpful) async {
    try {
      final reviewDoc = await _reviewsCollection.doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }

      final review = Review.fromJson(
          {...reviewDoc.data() as Map<String, dynamic>, 'id': reviewDoc.id});
      List<String> helpfulUserIds = List.from(review.helpfulUserIds);

      if (helpful) {
        if (!helpfulUserIds.contains(userId)) {
          helpfulUserIds.add(userId);
        }
      } else {
        helpfulUserIds.remove(userId);
      }

      await _reviewsCollection.doc(reviewId).update({
        'helpfulUserIds': helpfulUserIds,
        'helpfulCount': helpfulUserIds.length,
      });
    } catch (e) {
      throw Exception('Failed to mark review as helpful: $e');
    }
  }

  // Like/unlike a comment
  Future<void> likeComment(
      String reviewId, String commentId, String userId, bool like) async {
    try {
      final reviewDoc = await _reviewsCollection.doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }

      final review = Review.fromJson(
          {...reviewDoc.data() as Map<String, dynamic>, 'id': reviewDoc.id});
      List<ReviewComment> updatedComments = List.from(review.comments);

      // Find and update the comment
      bool commentFound = false;
      for (int i = 0; i < updatedComments.length; i++) {
        if (updatedComments[i].id == commentId) {
          commentFound = true;
          List<String> likedUserIds =
              List.from(updatedComments[i].likedByUserIds);

          if (like) {
            if (!likedUserIds.contains(userId)) {
              likedUserIds.add(userId);
            }
          } else {
            likedUserIds.remove(userId);
          }

          updatedComments[i] = updatedComments[i].copyWith(
            likedByUserIds: likedUserIds,
            likesCount: likedUserIds.length,
          );
          break;
        } else {
          // Check replies
          List<ReviewComment> replies = List.from(updatedComments[i].replies);
          for (int j = 0; j < replies.length; j++) {
            if (replies[j].id == commentId) {
              commentFound = true;
              List<String> likedUserIds = List.from(replies[j].likedByUserIds);

              if (like) {
                if (!likedUserIds.contains(userId)) {
                  likedUserIds.add(userId);
                }
              } else {
                likedUserIds.remove(userId);
              }

              replies[j] = replies[j].copyWith(
                likedByUserIds: likedUserIds,
                likesCount: likedUserIds.length,
              );
              updatedComments[i] =
                  updatedComments[i].copyWith(replies: replies);
              break;
            }
          }
        }
        if (commentFound) break;
      }

      if (!commentFound) {
        throw Exception('Comment not found');
      }

      await _reviewsCollection.doc(reviewId).update({
        'comments': updatedComments.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  // Report review/comment for moderation
  Future<void> reportContent({
    required String reviewId,
    String? commentId,
    required String reporterId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reviewId': reviewId,
        'commentId': commentId,
        'reporterId': reporterId,
        'reason': reason,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report content: $e');
    }
  }

  // Get user's reviews
  Future<List<Review>> getUserReviews(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _reviewsCollection
          .where('reviewerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Review.fromJson(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reviews: $e');
    }
  }

  // Private helper methods - Convert photos to base64 (cost-effective)
  Future<List<String>> _convertPhotosToBase64(List<File> photos) async {
    List<String> base64Photos = [];

    for (File photo in photos) {
      try {
        // Convert file to base64 using your existing ImageStorageService approach
        final base64String = await _imageStorage.fileToBase64(photo);
        base64Photos.add(base64String);
      } catch (e) {
        print('❌ Error converting photo to base64: $e');
        // Skip this photo but continue with others
      }
    }

    return base64Photos;
  }

  Future<void> _updateReviewSummary(
      String targetId, double rating, int increment) async {
    final docRef = _reviewSummariesCollection.doc(targetId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final summary = ReviewSummary.fromJson(data);

        final newTotalReviews = summary.totalReviews + increment;
        final newAverageRating =
            ((summary.averageRating * summary.totalReviews) + rating) /
                newTotalReviews;

        Map<int, int> newDistribution = Map.from(summary.ratingDistribution);
        final starRating = rating.round();
        newDistribution[starRating] =
            (newDistribution[starRating] ?? 0) + increment;

        transaction.update(docRef, {
          'averageRating': newAverageRating,
          'totalReviews': newTotalReviews,
          'ratingDistribution': newDistribution,
        });
      } else {
        // Create new summary
        Map<int, int> distribution = {};
        distribution[rating.round()] = 1;

        transaction.set(docRef, {
          'averageRating': rating,
          'totalReviews': 1,
          'ratingDistribution': distribution,
          'verifiedReviewsCount': 0,
        });
      }
    });
  }

  // Stream reviews for real-time updates
  Stream<List<Review>> streamReviews(String targetId) {
    return _reviewsCollection
        .where('targetId', isEqualTo: targetId)
        .where('moderationStatus', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  /// Update moderation status of a review
  Future<void> updateModerationStatus(
      String reviewId, ModerationStatus status) async {
    try {
      await _reviewsCollection.doc(reviewId).update({
        'moderationStatus': status.toString().split('.').last,
        'moderatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update moderation status: $e');
    }
  }
}

// Extension for ReviewComment
extension ReviewCommentExtension on ReviewComment {
  ReviewComment copyWith({
    String? id,
    String? commenterId,
    String? commenterName,
    String? commenterAvatar,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    ModerationStatus? moderationStatus,
    String? replyToId,
    List<ReviewComment>? replies,
    int? likesCount,
    List<String>? likedByUserIds,
  }) {
    return ReviewComment(
      id: id ?? this.id,
      commenterId: commenterId ?? this.commenterId,
      commenterName: commenterName ?? this.commenterName,
      commenterAvatar: commenterAvatar ?? this.commenterAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      replyToId: replyToId ?? this.replyToId,
      replies: replies ?? this.replies,
      likesCount: likesCount ?? this.likesCount,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
    );
  }
}
