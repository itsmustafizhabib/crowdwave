import 'package:flutter/material.dart';
import '../widgets/liquid_loading_indicator.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../services/enhanced_firebase_auth_service.dart';

class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  final ReviewService _reviewService = ReviewService();

  // Content moderation keywords and patterns
  final List<String> _profanityWords = [
    // Add appropriate profanity filtering words
    'spam', 'fake', 'scam', 'terrible', 'awful'
  ];

  final List<String> _spamPatterns = [
    r'\b(?:buy|visit|click|check)\s+(?:here|now|this)\b',
    r'\b(?:www\.|http|\.com|\.net|\.org)\b',
    r'\b(?:free|win|winner|prize|cash|money)\b.*\b(?:now|today|urgent)\b',
  ];

  // Auto-moderate content
  ModerationStatus autoModerateContent(String content) {
    final lowercaseContent = content.toLowerCase();

    // Check for profanity
    for (final word in _profanityWords) {
      if (lowercaseContent.contains(word)) {
        return ModerationStatus.flagged;
      }
    }

    // Check for spam patterns
    for (final pattern in _spamPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(content)) {
        return ModerationStatus.flagged;
      }
    }

    // Check content length (too short might be spam)
    if (content.trim().length < 10) {
      return ModerationStatus.pending;
    }

    // Check for excessive caps
    final capsCount = content.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (capsCount > content.length * 0.7) {
      return ModerationStatus.pending;
    }

    return ModerationStatus.approved;
  }

  // Report content
  Future<void> reportContent({
    required String reviewId,
    String? commentId,
    required String reporterId,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      await _reviewService.reportContent(
        reviewId: reviewId,
        commentId: commentId,
        reporterId: reporterId,
        reason: reason,
      );
    } catch (e) {
      throw Exception('Failed to report content: $e');
    }
  }

  // Get content safety score (0-100, higher is safer)
  int getContentSafetyScore(String content) {
    int score = 100;
    final lowercaseContent = content.toLowerCase();

    // Deduct points for profanity
    for (final word in _profanityWords) {
      if (lowercaseContent.contains(word)) {
        score -= 30;
      }
    }

    // Deduct points for spam patterns
    for (final pattern in _spamPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(content)) {
        score -= 25;
      }
    }

    // Deduct points for excessive caps
    final capsCount = content.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (capsCount > content.length * 0.5) {
      score -= 15;
    }

    // Deduct points for short content
    if (content.trim().length < 20) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }
}

class ReportContentDialog extends StatefulWidget {
  final String reviewId;
  final String? commentId;
  final String contentPreview;
  final Function(String reason, String? additionalInfo)? onReport;

  const ReportContentDialog({
    Key? key,
    required this.reviewId,
    this.commentId,
    required this.contentPreview,
    this.onReport,
  }) : super(key: key);

  @override
  State<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  String? _selectedReason;
  final _additionalInfoController = TextEditingController();
  bool _isSubmitting = false;

  final List<ReportReason> _reportReasons = [
    ReportReason(
      'spam',
      'Spam or unwanted commercial content',
      'This includes promotional content, advertisements, or repetitive messages.',
    ),
    ReportReason(
      'harassment',
      'Harassment or bullying',
      'Content that targets, intimidates, or bullies individuals.',
    ),
    ReportReason(
      'hate_speech',
      'Hate speech or discrimination',
      'Content that promotes hate or discrimination based on identity.',
    ),
    ReportReason(
      'violence',
      'Violence or dangerous organizations',
      'Content that promotes violence or dangerous activities.',
    ),
    ReportReason(
      'misinformation',
      'False or misleading information',
      'Content that contains factually incorrect information.',
    ),
    ReportReason(
      'inappropriate',
      'Inappropriate content',
      'Content that is not suitable for this platform.',
    ),
    ReportReason(
      'fake_review',
      'Fake or fraudulent review',
      'This review appears to be fake or not based on actual experience.',
    ),
    ReportReason(
      'other',
      'Other',
      'Please specify the reason in the additional information field.',
    ),
  ];

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    if (_selectedReason == 'other' &&
        _additionalInfoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please provide additional information for "Other" reports'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final additionalInfo = _additionalInfoController.text.trim().isEmpty
          ? null
          : _additionalInfoController.text.trim();

      // Get current user ID from Firebase Auth
      final currentUser = EnhancedFirebaseAuthService().currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to report content');
      }

      await ModerationService().reportContent(
        reviewId: widget.reviewId,
        commentId: widget.commentId,
        reporterId: currentUser.uid,
        reason: _selectedReason!,
        additionalInfo: additionalInfo,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onReport?.call(_selectedReason!, additionalInfo);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Content reported successfully. Thank you for helping keep our community safe.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.report, color: Colors.red[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report ${widget.commentId != null ? 'Comment' : 'Review'}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us understand what\'s wrong with this content',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reported Content:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.contentPreview,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Report Reasons
                    Text(
                      'Why are you reporting this content?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    const SizedBox(height: 12),

                    Column(
                      children: _reportReasons.map((reason) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedReason == reason.value
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: RadioListTile<String>(
                            title: Text(
                              reason.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              reason.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: reason.value,
                            groupValue: _selectedReason,
                            onChanged: (value) {
                              setState(() {
                                _selectedReason = value;
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Additional Information
                    const SizedBox(height: 16),
                    Text(
                      'Additional Information (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _additionalInfoController,
                      decoration: const InputDecoration(
                        hintText:
                            'Provide any additional context or details...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _selectedReason == null
                          ? null
                          : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Submit Report'),
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
}

class ReportReason {
  final String value;
  final String title;
  final String description;

  ReportReason(this.value, this.title, this.description);
}

// Content Safety Indicator Widget
class ContentSafetyIndicator extends StatelessWidget {
  final String content;
  final bool showDetails;

  const ContentSafetyIndicator({
    Key? key,
    required this.content,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final safetyScore = ModerationService().getContentSafetyScore(content);
    final moderationStatus = ModerationService().autoModerateContent(content);

    Color getStatusColor() {
      switch (moderationStatus) {
        case ModerationStatus.approved:
          return Colors.green;
        case ModerationStatus.pending:
          return Colors.orange;
        case ModerationStatus.flagged:
        case ModerationStatus.rejected:
          return Colors.red;
      }
    }

    String getStatusText() {
      switch (moderationStatus) {
        case ModerationStatus.approved:
          return 'Approved';
        case ModerationStatus.pending:
          return 'Pending Review';
        case ModerationStatus.flagged:
          return 'Flagged';
        case ModerationStatus.rejected:
          return 'Rejected';
      }
    }

    if (!showDetails) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: getStatusColor().withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield,
              size: 12,
              color: getStatusColor(),
            ),
            const SizedBox(width: 4),
            Text(
              getStatusText(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: getStatusColor(),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: getStatusColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Content Safety Assessment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Safety Score
            Row(
              children: [
                Text(
                  'Safety Score: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '$safetyScore/100',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: getStatusColor(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress Bar
            LinearProgressIndicator(
              value: safetyScore / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(getStatusColor()),
            ),

            const SizedBox(height: 12),

            // Status
            Row(
              children: [
                Text(
                  'Status: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    getStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Admin Moderation Panel Widget
class ModerationPanelWidget extends StatefulWidget {
  final Review review;
  final Function(Review)? onReviewUpdated;

  const ModerationPanelWidget({
    Key? key,
    required this.review,
    this.onReviewUpdated,
  }) : super(key: key);

  @override
  State<ModerationPanelWidget> createState() => _ModerationPanelWidgetState();
}

class _ModerationPanelWidgetState extends State<ModerationPanelWidget> {
  bool _isUpdating = false;

  Future<void> _updateModerationStatus(ModerationStatus status) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Update moderation status using ReviewService
      final reviewService = ReviewService();
      await reviewService.updateModerationStatus(widget.review.id, status);

      final updatedReview = widget.review.copyWith(moderationStatus: status);
      widget.onReviewUpdated?.call(updatedReview);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review ${status.toString().split('.').last}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Moderation Panel',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Current Status
            Row(
              children: [
                Text('Current Status: '),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.review.moderationStatus)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.review.moderationStatus
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(widget.review.moderationStatus),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Safety Assessment
            if (widget.review.comment != null)
              ContentSafetyIndicator(
                content: widget.review.comment!,
                showDetails: true,
              ),

            const SizedBox(height: 12),

            // Action Buttons
            if (_isUpdating)
              const CenteredLiquidLoading()
            else
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _updateModerationStatus(ModerationStatus.approved),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _updateModerationStatus(ModerationStatus.pending),
                    icon: const Icon(Icons.pending, size: 16),
                    label: const Text('Pending'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _updateModerationStatus(ModerationStatus.rejected),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return Colors.green;
      case ModerationStatus.pending:
        return Colors.orange;
      case ModerationStatus.flagged:
      case ModerationStatus.rejected:
        return Colors.red;
    }
  }
}
