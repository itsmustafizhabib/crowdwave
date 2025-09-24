import 'package:flutter/material.dart';
import '../widgets/liquid_loading_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/image_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/custom_image_widget.dart';

/// Example widget showing how to use Base64 image storage without Firebase Storage billing
/// This is a complete, standalone example you can reference or use directly
class Base64ImageUploadExample extends StatefulWidget {
  const Base64ImageUploadExample({Key? key}) : super(key: key);

  @override
  State<Base64ImageUploadExample> createState() =>
      _Base64ImageUploadExampleState();
}

class _Base64ImageUploadExampleState extends State<Base64ImageUploadExample> {
  final ImagePicker _imagePicker = ImagePicker();
  final UserProfileService _userProfileService = UserProfileService();

  String? _currentImageBase64;
  bool _isUploading = false;
  Map<String, dynamic>? _lastImageInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base64 Image Upload Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title and explanation
            const Text(
              'FREE Profile Picture Storage',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                '✅ No Firebase Storage billing\n'
                '✅ Images stored as Base64 in Firestore\n'
                '✅ Automatic compression for large images\n'
                '✅ Works with camera and gallery',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Current image display
            GestureDetector(
              onTap: _showImagePickerBottomSheet,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _currentImageBase64 != null
                      ? CustomImageWidget(
                          imageUrl: _currentImageBase64,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.add_a_photo,
                            color: Colors.grey.shade400,
                            size: 50,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Upload button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _showImagePickerBottomSheet,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: LiquidLoadingIndicator(size: 20),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_isUploading ? 'Processing...' : 'Upload Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Image info display
            if (_lastImageInfo != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Dimensions: ${_lastImageInfo!['width']} x ${_lastImageInfo!['height']}'),
                    Text('Original Size: ${_lastImageInfo!['fileSizeMB']} MB'),
                    Text('Storage: Firestore (Base64)'),
                    Text('Cost: FREE! 🎉'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Instructions
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('1. Pick an image from camera or gallery'),
                      Text('2. Image is automatically compressed if needed'),
                      Text('3. Converted to Base64 format'),
                      Text('4. Stored directly in Firestore document'),
                      Text('5. No Firebase Storage charges!'),
                      SizedBox(height: 16),
                      Text(
                        'Benefits:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Completely FREE storage'),
                      Text('• No additional Firebase setup'),
                      Text('• Automatic image optimization'),
                      Text('• Works offline once loaded'),
                      Text('• Simple implementation'),
                      SizedBox(height: 16),
                      Text(
                        'Limitations:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Max ~800KB per image (Firestore limit)'),
                      Text('• Not ideal for very high-res images'),
                      Text('• Slightly slower initial load'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                if (_currentImageBase64 != null)
                  _buildImageSourceOption(
                    icon: Icons.delete_outline,
                    label: 'Remove',
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.blue,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      setState(() => _isUploading = true);

      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isUploading = false);
        return;
      }

      final imageFile = File(image.path);

      // Get image info
      final imageInfo = await ImageService.getImageInfo(imageFile);
      print('Picked image info: $imageInfo');

      // Convert to Base64
      final base64Data = await ImageService.imageFileToBase64(imageFile);

      // Update profile (optional - you can just store locally for demo)
      await _userProfileService.updateUserProfile(photoUrl: base64Data);

      setState(() {
        _currentImageBase64 = base64Data;
        _lastImageInfo = imageInfo;
        _isUploading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Image saved! Size: ${imageInfo['fileSizeMB']} MB'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _currentImageBase64 = null;
      _lastImageInfo = null;
    });

    // Also update profile
    _userProfileService.updateUserProfile(photoUrl: '');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
