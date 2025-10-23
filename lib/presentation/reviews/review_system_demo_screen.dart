import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/review_model.dart';
import '../../widgets/star_rating_widget.dart';
import '../../widgets/moderation_widgets.dart';
import 'create_review_screen.dart';
import 'review_list_screen.dart';

class ReviewSystemDemoScreen extends StatefulWidget {
  const ReviewSystemDemoScreen({Key? key}) : super(key: key);

  @override
  State<ReviewSystemDemoScreen> createState() => _ReviewSystemDemoScreenState();
}

class _ReviewSystemDemoScreenState extends State<ReviewSystemDemoScreen> {
  double _demoRating = 0.0;

  // Sample data for demo
  final Review _sampleReview = Review(
    id: 'demo_review_1',
    reviewerId: 'user_123',
    reviewerName: 'John Doe',
    reviewerAvatar: null,
    targetId: 'trip_456',
    type: ReviewType.trip,
    rating: 4.5,
    comment:
        'Great trip! The traveler was very professional and delivered my package safely. Highly recommended for future deliveries.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    moderationStatus: ModerationStatus.approved,
    isVerifiedBooking: true,
    comments: [
      ReviewComment(
        id: 'comment_1',
        commenterId: 'user_789',
        commenterName: 'Jane Smith',
        content: 'Thank you for the positive feedback!',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        moderationStatus: ModerationStatus.approved,
        replies: [
          ReviewComment(
            id: 'reply_1',
            commenterId: 'user_123',
            commenterName: 'John Doe',
            content:
                'You\'re welcome! Looking forward to working with you again.',
            createdAt: DateTime.now().subtract(const Duration(hours: 12)),
            moderationStatus: ModerationStatus.approved,
            replyToId: 'comment_1',
          ),
        ],
      ),
    ],
    helpfulCount: 5,
    helpfulUserIds: [
      'user_111',
      'user_222',
      'user_333',
      'user_444',
      'user_555'
    ],
  );

  final ReviewSummary _sampleSummary = ReviewSummary(
    averageRating: 4.3,
    totalReviews: 25,
    ratingDistribution: {5: 12, 4: 8, 3: 3, 2: 1, 1: 1},
    verifiedReviewsCount: 20,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('reviews.demo_title'.tr()),
        backgroundColor: const Color(0xFF215C5C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('✨ Review & Rating System Overview'),
            _buildFeaturesList(),
            const SizedBox(height: 24),
            _buildSectionHeader('⭐ Star Rating Widget Demo'),
            _buildStarRatingDemo(),
            const SizedBox(height: 24),
            _buildSectionHeader('📊 Rating Summary Widget'),
            _buildRatingSummaryDemo(),
            const SizedBox(height: 24),
            _buildSectionHeader('📝 Sample Review Card'),
            _buildSampleReviewCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('💬 Comment System Demo'),
            _buildCommentSystemDemo(),
            const SizedBox(height: 24),
            _buildSectionHeader('🛡️ Content Moderation'),
            _buildModerationDemo(),
            const SizedBox(height: 24),
            _buildSectionHeader('🔧 Test Actions'),
            _buildTestActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF215C5C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF215C5C).withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF215C5C),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      '⭐ 5-star rating system with half-star support',
      '📝 Text reviews with photo attachments',
      '💬 Nested comments & replies (2 levels)',
      '👍 Helpful/Like system for reviews & comments',
      '🛡️ Content moderation with auto-flagging',
      '📊 Review analytics & summaries',
      '🔍 Advanced filtering & sorting',
      '📱 Real-time updates via Firestore',
      '🚫 Report system for inappropriate content',
      '✅ Verified booking indicators',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Implemented Features:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(feature, style: const TextStyle(fontSize: 14)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRatingDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interactive Rating:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            StarRatingWidget(
              rating: _demoRating,
              size: 32,
              onRatingChanged: (rating) {
                setState(() {
                  _demoRating = rating;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Current Rating: ${_demoRating.toStringAsFixed(1)} stars'),
            const SizedBox(height: 16),
            const Text(
              'Display Only (Compact):',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const CompactStarRating(
              rating: 4.2,
              reviewCount: 128,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummaryDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RatingSummaryWidget(
          averageRating: _sampleSummary.averageRating,
          totalReviews: _sampleSummary.totalReviews,
          distribution: _sampleSummary.ratingDistribution,
        ),
      ),
    );
  }

  Widget _buildSampleReviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(_sampleReview.reviewerName[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _sampleReview.reviewerName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (_sampleReview.isVerifiedBooking) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('profile.verified'.tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StarRatingWidget(
                            rating: _sampleReview.rating,
                            size: 16,
                            isReadOnly: true,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '2 days ago',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Review Content
            Text(_sampleReview.comment ?? ''),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful (${_sampleReview.helpfulCount})'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.comment_outlined, size: 16),
                  label: Text('Comments (${_sampleReview.comments.length})'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSystemDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sample Comment Thread:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Top-level comment
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(_sampleReview.comments.first.commenterName[0]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sampleReview.comments.first.commenterName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sampleReview.comments.first.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Reply (nested)
            Container(
              margin: const EdgeInsets.only(left: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text(_sampleReview
                        .comments.first.replies.first.commenterName[0]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sampleReview
                              .comments.first.replies.first.commenterName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _sampleReview.comments.first.replies.first.content,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationDemo() {
    return Column(
      children: [
        ContentSafetyIndicator(
          content: 'This is a great service! Highly recommend.',
          showDetails: true,
        ),
        const SizedBox(height: 12),
        ContentSafetyIndicator(
          content: 'SPAM SPAM VISIT WWW.FAKE.COM NOW!!!',
          showDetails: true,
        ),
      ],
    );
  }

  Widget _buildTestActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Review System:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateReviewScreen(
                            targetId: 'demo_trip_123',
                            reviewType: ReviewType.trip,
                            targetName: 'Demo Trip: New York → Los Angeles',
                            isVerifiedBooking: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review),
                    label: Text('reviews.create_review'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ReviewListScreen(
                            targetId: 'demo_trip_123',
                            reviewType: ReviewType.trip,
                            targetName: 'Demo Trip',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: Text('reviews.view_reviews'.tr()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ReportContentDialog(
                      reviewId: 'demo_review_123',
                      contentPreview:
                          'This is a sample review that might contain inappropriate content...',
                    ),
                  );
                },
                icon: const Icon(Icons.report),
                label: Text('reviews.test_report_dialog'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
