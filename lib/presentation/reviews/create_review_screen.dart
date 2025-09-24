import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../services/enhanced_firebase_auth_service.dart';
import '../../widgets/star_rating_widget.dart';

class CreateReviewScreen extends StatefulWidget {
  final String targetId;
  final ReviewType reviewType;
  final String targetName; // Trip title or package description
  final String? targetImageUrl;
  final bool isVerifiedBooking;

  const CreateReviewScreen({
    Key? key,
    required this.targetId,
    required this.reviewType,
    required this.targetName,
    this.targetImageUrl,
    this.isVerifiedBooking = false,
  }) : super(key: key);

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _reviewService = ReviewService();
  final _imagePicker = ImagePicker();

  double _rating = 0.0;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;
  bool _showImageOptions = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(
            images
                .take(5 - _selectedImages.length)
                .map((xFile) => File(xFile.path)),
          );
          _showImageOptions = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Unable to select images. Please try again.');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && _selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(File(image.path));
          _showImageOptions = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Unable to take photo. Please try again.');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      _showErrorSnackBar('Please provide a rating');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get actual user data from auth service
      final currentUser = EnhancedFirebaseAuthService().currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to create reviews');
      }

      final String currentUserId = currentUser.uid;
      final String currentUserName =
          currentUser.displayName ?? 'Anonymous User';
      final String? currentUserAvatar = currentUser.photoURL;

      await _reviewService.createReview(
        reviewerId: currentUserId,
        reviewerName: currentUserName,
        reviewerAvatar: currentUserAvatar,
        targetId: widget.targetId,
        type: widget.reviewType,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        photos: _selectedImages.isEmpty ? null : _selectedImages,
        isVerifiedBooking: widget.isVerifiedBooking,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Convert technical errors to user-friendly messages
      String userFriendlyMessage = _getErrorMessage(e.toString());
      _showErrorSnackBar(userFriendlyMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getErrorMessage(String error) {
    // Convert technical errors to user-friendly messages
    String lowerError = error.toLowerCase();

    if (lowerError.contains('permission') ||
        lowerError.contains('permission-denied')) {
      return 'You don\'t have permission to submit reviews at this time. Please try again later.';
    } else if (lowerError.contains('network') ||
        lowerError.contains('connection')) {
      return 'Network connection issue. Please check your internet and try again.';
    } else if (lowerError.contains('not found') ||
        lowerError.contains('does not exist')) {
      return 'The item you\'re trying to review no longer exists.';
    } else if (lowerError.contains('authentication') ||
        lowerError.contains('auth')) {
      return 'Please sign in again to submit your review.';
    } else if (lowerError.contains('quota') || lowerError.contains('limit')) {
      return 'Service temporarily unavailable. Please try again in a few minutes.';
    } else {
      return 'Unable to submit your review. Please try again later.';
    }
  }

  String _getRatingDescription(double rating) {
    if (rating == 0) return 'Tap to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  Widget _buildRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Rate your experience',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            StarRatingWidget(
              rating: _rating,
              size: 40.0,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingDescription(_rating),
              style: TextStyle(
                fontSize: 16,
                color:
                    _rating > 0 ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your experience (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Tell others about your experience...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Comment cannot exceed 500 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${_commentController.text.length}/500',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add photos (optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${_selectedImages.length}/5',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Selected Images
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Add Photo Button
            if (_selectedImages.length < 5)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showImageOptions = !_showImageOptions;
                    });
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Photos'),
                ),
              ),

            // Image Options
            if (_showImageOptions) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Target Image
            if (widget.targetImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.targetImageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.reviewType == ReviewType.trip
                      ? Icons.flight
                      : Icons.local_shipping,
                  color: Colors.grey,
                ),
              ),

            const SizedBox(width: 12),

            // Target Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.targetName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        widget.reviewType == ReviewType.trip
                            ? Icons.flight
                            : Icons.local_shipping,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.reviewType == ReviewType.trip
                            ? 'Trip'
                            : 'Package',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (widget.isVerifiedBooking) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Verified',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Review'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTargetInfo(),
                    const SizedBox(height: 16),
                    _buildRatingSection(),
                    const SizedBox(height: 16),
                    _buildCommentSection(),
                    const SizedBox(height: 16),
                    _buildPhotosSection(),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: EdgeInsets.fromLTRB(
                16.0,
                16.0,
                16.0,
                16.0 + MediaQuery.of(context).viewPadding.bottom,
              ),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
