import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/delivery_tracking.dart';

class DeliveryFeedbackScreen extends StatefulWidget {
  final DeliveryTracking tracking;

  const DeliveryFeedbackScreen({
    Key? key,
    required this.tracking,
  }) : super(key: key);

  @override
  State<DeliveryFeedbackScreen> createState() => _DeliveryFeedbackScreenState();
}

class _DeliveryFeedbackScreenState extends State<DeliveryFeedbackScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _feedbackController = TextEditingController();

  double _rating = 0;
  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  final List<String> _quickTags = [
    'Fast',
    'Professional',
    'Careful',
    'Friendly',
    'On Time',
    'Good Communication',
    'Reliable',
    'Careful Handling',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      Get.snackbar(
        '⚠️ Rating Required',
        'Please select a rating before submitting',
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      // Update tracking with feedback and rating
      await _firestore
          .collection('deliveryTracking')
          .doc(widget.tracking.id)
          .update({
        'senderRating': _rating,
        'senderFeedback': _feedbackController.text.trim(),
        'feedbackTags': _selectedTags.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update traveler's rating (simplified - in production, calculate average)
      try {
        final travelerRef =
            _firestore.collection('users').doc(widget.tracking.travelerId);
        final travelerDoc = await travelerRef.get();

        if (travelerDoc.exists) {
          final data = travelerDoc.data()!;
          final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
          final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;

          final newRatingCount = ratingCount + 1;
          final newRating =
              ((currentRating * ratingCount) + _rating) / newRatingCount;

          await travelerRef.update({
            'rating': newRating,
            'ratingCount': newRatingCount,
          });
        }
      } catch (e) {
        print('⚠️ Error updating traveler rating: $e');
        // Don't fail the whole operation if rating update fails
      }

      Get.snackbar(
        '✅ Thank You!',
        'Your feedback has been submitted successfully',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      // Navigate back to home or tracking list
      Get.back();
      Get.back(); // Go back twice to return to main screen
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'Failed to submit feedback: $e',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _skipFeedback() {
    Get.back();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('tracking.rate_experience'.tr()),
        backgroundColor: const Color(0xFF6A5AE0),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _skipFeedback,
            child: Text('onboarding.skip'.tr(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              const Icon(
                Icons.star_rounded,
                size: 80,
                color: Color(0xFFFFD700),
              ),
              const SizedBox(height: 16),

              // Title
              Text('tracking.feedback_hint'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text('common.your_feedback_helps_us_improve_our_service'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              // Star Rating
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1.0;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starValue;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          _rating >= starValue
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 50,
                          color: _rating >= starValue
                              ? const Color(0xFFFFD700)
                              : Colors.grey[300],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (_rating > 0) ...[
                const SizedBox(height: 8),
                Text(
                  _getRatingText(_rating),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A5AE0),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Quick Tags
              Text('common.what_did_you_like'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF6A5AE0).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF6A5AE0),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6A5AE0)
                          : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF6A5AE0)
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              // Feedback Text
              const Text(
                'Additional Feedback (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'travel.share_your_experience_with_the_traveler'.tr(),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6A5AE0),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A5AE0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('tracking.submit_feedback'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5.0) return 'Excellent!';
    if (rating >= 4.0) return 'Great!';
    if (rating >= 3.0) return 'Good';
    if (rating >= 2.0) return 'Fair';
    return 'Needs Improvement';
  }
}
