import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/liquid_loading_indicator.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../services/enhanced_firebase_auth_service.dart';
import '../../widgets/star_rating_widget.dart';
import '../../widgets/comment_system_widget.dart';
import 'create_review_screen.dart';

class ReviewListScreen extends StatefulWidget {
  final String targetId;
  final ReviewType reviewType;
  final String targetName;

  const ReviewListScreen({
    Key? key,
    required this.targetId,
    required this.reviewType,
    required this.targetName,
  }) : super(key: key);

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen>
    with TickerProviderStateMixin {
  final _reviewService = ReviewService();
  late TabController _tabController;

  List<Review> _reviews = [];
  ReviewSummary? _reviewSummary;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  ReviewFilter _currentFilter = ReviewFilter();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReviewSummary();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadReviewSummary() async {
    try {
      final summary = await _reviewService.getReviewSummary(widget.targetId);
      if (mounted) {
        setState(() {
          _reviewSummary = summary;
        });
      }
    } catch (e) {
      print('Error loading review summary: $e');
    }
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (!refresh && _isLoading) return;

    setState(() {
      if (refresh) {
        _reviews.clear();
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final reviews = await _reviewService.getReviews(
        targetId: widget.targetId,
        filter: _currentFilter,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || _reviews.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // For demo purposes - in real app, use lastDocument for pagination
      await _reviewService.getReviews(
        targetId: widget.targetId,
        filter: _currentFilter,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          // In real implementation, append new reviews
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilter(ReviewFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    _loadReviews(refresh: true);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReviewFilterBottomSheet(
        currentFilter: _currentFilter,
        onApplyFilter: _applyFilter,
      ),
    );
  }

  Future<void> _navigateToCreateReview() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateReviewScreen(
          targetId: widget.targetId,
          reviewType: widget.reviewType,
          targetName: widget.targetName,
        ),
      ),
    );

    if (result == true) {
      _loadReviewSummary();
      _loadReviews(refresh: true);
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_reviewSummary != null) ...[
            RatingSummaryWidget(
              averageRating: _reviewSummary!.averageRating,
              totalReviews: _reviewSummary!.totalReviews,
              distribution: _reviewSummary!.ratingDistribution,
            ),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'reviews.recent_reviews'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.list),
                label: Text('reviews.view_all'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            CenteredLiquidLoading()
          else if (_error != null)
            _buildErrorWidget()
          else if (_reviews.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.take(3).length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return ReviewCard(
                  review: _reviews[index],
                  showComments: false,
                  onReviewUpdated: (updatedReview) {
                    _loadReviews(); // Refresh the reviews list
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAllReviewsTab() {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_reviews.length} reviews',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: _showFilterBottomSheet,
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
        ),

        // Reviews List
        Expanded(
          child: _isLoading
              ? CenteredLiquidLoading()
              : _error != null
                  ? _buildErrorWidget()
                  : _reviews.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _reviews.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == _reviews.length) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            return ReviewCard(
                              review: _reviews[index],
                              showComments: true,
                              onReviewUpdated: (updatedReview) {
                                _loadReviews(); // Refresh the reviews list
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'error_messages.failed_to_load_reviews'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadReviews(refresh: true),
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star_border,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'no reviews',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'common.be_the_first_to_share_your_experience'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _navigateToCreateReview,
            child: Text('reviews.write_review'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('reviews.reviews_for'
            .tr(namedArgs: {'targetName': widget.targetName})),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'common.overview'.tr()),
            Tab(text: 'reviews.all_reviews'.tr()),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToCreateReview,
            icon: const Icon(Icons.add),
            tooltip: 'Write Review',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAllReviewsTab(),
        ],
      ),
    );
  }
}

class ReviewCard extends StatefulWidget {
  final Review review;
  final bool showComments;
  final Function(Review)? onReviewUpdated;

  const ReviewCard({
    Key? key,
    required this.review,
    this.showComments = true,
    this.onReviewUpdated,
  }) : super(key: key);

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _showAllPhotos = false;
  bool _isExpanded = false;

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildPhotos() {
    if (widget.review.photoUrls == null || widget.review.photoUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    final photos = widget.review.photoUrls!;
    final displayPhotos = _showAllPhotos ? photos : photos.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayPhotos.length +
                (photos.length > 3 && !_showAllPhotos ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == displayPhotos.length) {
                // Show "more" button
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAllPhotos = true;
                    });
                  },
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey[600]),
                        const SizedBox(height: 4),
                        Text(
                          '+${photos.length - 3}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  displayPhotos[index],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.review.reviewerAvatar != null
                      ? NetworkImage(widget.review.reviewerAvatar!)
                      : null,
                  child: widget.review.reviewerAvatar == null
                      ? Text(widget.review.reviewerName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.review.reviewerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.review.isVerifiedBooking) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'profile.verified'.tr(),
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
                            rating: widget.review.rating,
                            size: 16,
                            isReadOnly: true,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimeAgo(widget.review.createdAt),
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
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Text('reviews.report'.tr()),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportDialog(context, widget.review);
                    }
                  },
                ),
              ],
            ),

            // Comment
            if (widget.review.comment != null &&
                widget.review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.review.comment!,
                style: const TextStyle(fontSize: 14),
                maxLines: _isExpanded ? null : 3,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
              ),
              if (widget.review.comment!.length > 150) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],

            // Photos
            _buildPhotos(),

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    _toggleHelpful(context, widget.review);
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('reviews.helpful_count'.tr(namedArgs: {
                    'count': widget.review.helpfulCount.toString()
                  })),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                ),
                if (widget.showComments &&
                    widget.review.comments.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () {
                      _showCommentsDialog(context, widget.review);
                    },
                    icon: const Icon(Icons.comment_outlined, size: 16),
                    label: Text('reviews.comments_count'.tr(namedArgs: {
                      'count': widget.review.comments.length.toString()
                    })),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleHelpful(BuildContext context, Review review) async {
    try {
      final currentUser = EnhancedFirebaseAuthService().currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('reviews.sign_in_helpful'.tr()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final reviewService = ReviewService();
      final isCurrentlyHelpful =
          review.helpfulUserIds.contains(currentUser.uid);

      await reviewService.markReviewHelpful(
        review.id,
        currentUser.uid,
        !isCurrentlyHelpful,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyHelpful
                  ? 'Removed helpful vote'
                  : 'Marked as helpful!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the review list if there's a callback
        if (widget.onReviewUpdated != null) {
          widget.onReviewUpdated!(review);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('reviews.helpful_update_failed'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reviews.report_review'.tr()),
        content: Text(
            'reviews.are_you_sure_you_want_to_report_this_review_for_in'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _reportReview(context, review);
            },
            child: Text(
              'comments.report'.tr(),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportReview(BuildContext context, Review review) async {
    try {
      final currentUser = EnhancedFirebaseAuthService().currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('reviews.sign_in_report'.tr()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final reviewService = ReviewService();
      await reviewService.reportContent(
        reviewId: review.id,
        reporterId: currentUser.uid,
        reason: 'Inappropriate content',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('reviews.reported_successfully'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('reviews.report_failed'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCommentsDialog(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'common.comments'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: CommentSystemWidget(
                  review: review,
                  onReviewUpdated: (updatedReview) {
                    // Update the review in the parent widget if callback exists
                    if (widget.onReviewUpdated != null) {
                      widget.onReviewUpdated!(updatedReview);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewFilterBottomSheet extends StatefulWidget {
  final ReviewFilter currentFilter;
  final Function(ReviewFilter) onApplyFilter;

  const ReviewFilterBottomSheet({
    Key? key,
    required this.currentFilter,
    required this.onApplyFilter,
  }) : super(key: key);

  @override
  State<ReviewFilterBottomSheet> createState() =>
      _ReviewFilterBottomSheetState();
}

class _ReviewFilterBottomSheetState extends State<ReviewFilterBottomSheet> {
  late ReviewFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = ReviewFilter(
      starRatings: widget.currentFilter.starRatings,
      verifiedOnly: widget.currentFilter.verifiedOnly,
      withPhotos: widget.currentFilter.withPhotos,
      withComments: widget.currentFilter.withComments,
      sortBy: widget.currentFilter.sortBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'reviews.filter_reviews'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filter = ReviewFilter();
                  });
                },
                child: Text('reviews.clear'.tr()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Star Rating Filter
          Text(
            'profile.rating'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(5, (index) {
              final star = 5 - index;
              final isSelected = _filter.starRatings?.contains(star) ?? false;

              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$star'),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 16),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _filter = ReviewFilter(
                        starRatings: [...(_filter.starRatings ?? []), star],
                        verifiedOnly: _filter.verifiedOnly,
                        withPhotos: _filter.withPhotos,
                        withComments: _filter.withComments,
                        sortBy: _filter.sortBy,
                      );
                    } else {
                      _filter = ReviewFilter(
                        starRatings: (_filter.starRatings ?? [])..remove(star),
                        verifiedOnly: _filter.verifiedOnly,
                        withPhotos: _filter.withPhotos,
                        withComments: _filter.withComments,
                        sortBy: _filter.sortBy,
                      );
                    }
                  });
                },
              );
            }),
          ),

          const SizedBox(height: 24),

          // Other Filters
          CheckboxListTile(
            title: Text('reviews.verified_bookings_only'.tr()),
            value: _filter.verifiedOnly ?? false,
            onChanged: (value) {
              setState(() {
                _filter = ReviewFilter(
                  starRatings: _filter.starRatings,
                  verifiedOnly: value,
                  withPhotos: _filter.withPhotos,
                  withComments: _filter.withComments,
                  sortBy: _filter.sortBy,
                );
              });
            },
          ),

          CheckboxListTile(
            title: Text('reviews.with_photos'.tr()),
            value: _filter.withPhotos ?? false,
            onChanged: (value) {
              setState(() {
                _filter = ReviewFilter(
                  starRatings: _filter.starRatings,
                  verifiedOnly: _filter.verifiedOnly,
                  withPhotos: value,
                  withComments: _filter.withComments,
                  sortBy: _filter.sortBy,
                );
              });
            },
          ),

          CheckboxListTile(
            title: Text('reviews.with_comments'.tr()),
            value: _filter.withComments ?? false,
            onChanged: (value) {
              setState(() {
                _filter = ReviewFilter(
                  starRatings: _filter.starRatings,
                  verifiedOnly: _filter.verifiedOnly,
                  withPhotos: _filter.withPhotos,
                  withComments: value,
                  sortBy: _filter.sortBy,
                );
              });
            },
          ),

          const SizedBox(height: 24),

          // Sort Options
          Text(
            'common.sort_by'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<ReviewSortBy>(
            initialValue: _filter.sortBy,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                  value: ReviewSortBy.newest,
                  child: Text('reviews.sort_newest'.tr())),
              DropdownMenuItem(
                  value: ReviewSortBy.oldest,
                  child: Text('reviews.sort_oldest'.tr())),
              DropdownMenuItem(
                  value: ReviewSortBy.highestRated,
                  child: Text('reviews.sort_highest'.tr())),
              DropdownMenuItem(
                  value: ReviewSortBy.lowestRated,
                  child: Text('reviews.sort_lowest'.tr())),
              DropdownMenuItem(
                  value: ReviewSortBy.mostHelpful,
                  child: Text('reviews.sort_helpful'.tr())),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filter = ReviewFilter(
                    starRatings: _filter.starRatings,
                    verifiedOnly: _filter.verifiedOnly,
                    withPhotos: _filter.withPhotos,
                    withComments: _filter.withComments,
                    sortBy: value,
                  );
                });
              }
            },
          ),

          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilter(_filter);
                Navigator.of(context).pop();
              },
              child: Text('common.apply_filters'.tr()),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
