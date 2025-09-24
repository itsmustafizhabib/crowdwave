import 'package:flutter/material.dart';
import '../widgets/liquid_loading_indicator.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../services/enhanced_firebase_auth_service.dart';

class CommentSystemWidget extends StatefulWidget {
  final Review review;
  final Function(Review)? onReviewUpdated;

  const CommentSystemWidget({
    Key? key,
    required this.review,
    this.onReviewUpdated,
  }) : super(key: key);

  @override
  State<CommentSystemWidget> createState() => _CommentSystemWidgetState();
}

class _CommentSystemWidgetState extends State<CommentSystemWidget> {
  final _reviewService = ReviewService();
  final _commentController = TextEditingController();
  bool _isAddingComment = false;
  bool _isSubmittingComment = false;
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _refreshReview() async {
    try {
      final refreshedReview =
          await _reviewService.getReviewById(widget.review.id);
      if (refreshedReview != null) {
        widget.onReviewUpdated?.call(refreshedReview);
      }
    } catch (e) {
      // Silently handle refresh errors - user still sees the success feedback
      debugPrint('Failed to refresh review: $e');
    }
  }

  Future<void> _addComment({String? replyToId}) async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      // Get actual user data from auth service
      final currentUser = EnhancedFirebaseAuthService().currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to add comments');
      }

      await _reviewService.addComment(
        reviewId: widget.review.id,
        commenterId: currentUser.uid,
        commenterName: currentUser.displayName ?? 'Anonymous User',
        content: _commentController.text.trim(),
        replyToId: _replyToId ?? replyToId,
      );

      _commentController.clear();
      setState(() {
        _isAddingComment = false;
        _isSubmittingComment = false;
        _replyToId = null;
        _replyToName = null;
      });

      // Refresh the review to get updated comments
      await _refreshReview();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmittingComment = false;
        _replyToId = null;
        _replyToName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _likeComment(ReviewComment comment, bool like) async {
    try {
      final currentUser = EnhancedFirebaseAuthService().currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to like comments');
      }

      await _reviewService.likeComment(
        widget.review.id,
        comment.id,
        currentUser.uid,
        like,
      );

      // Update UI to reflect the like change
      await _refreshReview();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${like ? 'Liked' : 'Unliked'} comment successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${like ? 'like' : 'unlike'} comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCommentInput({String? replyToId, String? replyToName}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyToName != null) ...[
            Row(
              children: [
                Text(
                  'Replying to $replyToName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isAddingComment = false;
                      _replyToId = null;
                      _replyToName = null;
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: replyToName != null
                        ? 'Write a reply...'
                        : 'Add a comment...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 300,
                  buildCounter: (context,
                      {required currentLength, required isFocused, maxLength}) {
                    if (!isFocused) return null;
                    return Text(
                      '$currentLength/${maxLength ?? ""}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSubmittingComment
                    ? null
                    : () => _addComment(replyToId: replyToId),
                icon: _isSubmittingComment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: LiquidLoadingIndicator(size: 20),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComment(ReviewComment comment, {bool isReply = false}) {
    final currentUser = EnhancedFirebaseAuthService().currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final isLikedByUser = comment.likedByUserIds.contains(currentUserId);

    return Container(
      margin: EdgeInsets.only(
        left: isReply ? 32.0 : 0,
        bottom: 12.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 16,
                backgroundImage: comment.commenterAvatar != null
                    ? NetworkImage(comment.commenterAvatar!)
                    : null,
                child: comment.commenterAvatar == null
                    ? Text(
                        comment.commenterName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: isReply ? 12 : 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment Header
                    Row(
                      children: [
                        Text(
                          comment.commenterName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isReply ? 13 : 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: TextStyle(
                            fontSize: isReply ? 11 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Comment Content
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: isReply ? 13 : 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Comment Actions
                    Row(
                      children: [
                        // Like Button
                        GestureDetector(
                          onTap: () => _likeComment(comment, !isLikedByUser),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLikedByUser
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                size: 16,
                                color: isLikedByUser
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                              ),
                              if (comment.likesCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.likesCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLikedByUser
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Reply Button (only for top-level comments)
                        if (!isReply && comment.canHaveReplies) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAddingComment = true;
                                _replyToId = comment.id;
                                _replyToName = comment.commenterName;
                              });
                            },
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Report Button
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Report'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'report') {
                              _reportComment(comment);
                            }
                          },
                          child: Icon(
                            Icons.more_horiz,
                            size: 16,
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

          // Replies
          if (!isReply && comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              children: comment.replies
                  .map((reply) => _buildComment(reply, isReply: true))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _reportComment(ReviewComment comment) {
    showDialog(
      context: context,
      builder: (context) => ReportCommentDialog(
        comment: comment,
        onReport: (reason) async {
          try {
            final currentUser = EnhancedFirebaseAuthService().currentUser;
            if (currentUser == null) {
              throw Exception('You must be logged in to report comments');
            }

            await _reviewService.reportContent(
              reviewId: widget.review.id,
              commentId: comment.id,
              reporterId: currentUser.uid,
              reason: reason,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comment reported successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to report comment: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topLevelComments =
        widget.review.comments.where((comment) => !comment.isReply).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments Header
        if (topLevelComments.isNotEmpty) ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Comments (${topLevelComments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          // Comments List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: topLevelComments.length,
            itemBuilder: (context, index) {
              return _buildComment(topLevelComments[index]);
            },
          ),
        ],

        // Add Comment Button
        if (!_isAddingComment)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAddingComment = true;
                  });
                },
                icon: const Icon(Icons.add_comment),
                label: const Text('Add Comment'),
              ),
            ),
          ),

        // Comment Input
        if (_isAddingComment)
          _buildCommentInput(
            replyToId: _replyToId,
            replyToName: _replyToName,
          ),
      ],
    );
  }
}

class ReportCommentDialog extends StatefulWidget {
  final ReviewComment comment;
  final Function(String) onReport;

  const ReportCommentDialog({
    Key? key,
    required this.comment,
    required this.onReport,
  }) : super(key: key);

  @override
  State<ReportCommentDialog> createState() => _ReportCommentDialogState();
}

class _ReportCommentDialogState extends State<ReportCommentDialog> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();

  final List<String> _reportReasons = [
    'Spam or unwanted commercial content',
    'Harassment or bullying',
    'Hate speech or discrimination',
    'Violence or dangerous organizations',
    'Misinformation',
    'Inappropriate content',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Comment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why are you reporting this comment?'),
          const SizedBox(height: 16),

          // Comment Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.comment.content,
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 16),

          // Report Reasons
          Column(
            children: _reportReasons.map((reason) {
              return RadioListTile<String>(
                title: Text(
                  reason,
                  style: const TextStyle(fontSize: 14),
                ),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
          ),

          // Custom Reason Input
          if (_selectedReason == 'Other') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customReasonController,
              decoration: const InputDecoration(
                hintText: 'Please specify...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              maxLength: 200,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason != null
              ? () {
                  final reason = _selectedReason == 'Other'
                      ? _customReasonController.text.trim()
                      : _selectedReason!;

                  if (reason.isNotEmpty) {
                    widget.onReport(reason);
                    Navigator.of(context).pop();
                  }
                }
              : null,
          child: const Text('Report'),
        ),
      ],
    );
  }
}

// Compact Comments Widget for Review Cards
class CompactCommentsWidget extends StatelessWidget {
  final Review review;
  final VoidCallback? onTap;

  const CompactCommentsWidget({
    Key? key,
    required this.review,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topLevelComments =
        review.comments.where((comment) => !comment.isReply).toList();

    if (topLevelComments.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${topLevelComments.length} comment${topLevelComments.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            if (topLevelComments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                topLevelComments.first.content,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (topLevelComments.length > 1) ...[
                const SizedBox(height: 4),
                Text(
                  'and ${topLevelComments.length - 1} more comment${topLevelComments.length - 1 != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
