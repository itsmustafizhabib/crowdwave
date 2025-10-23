import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:easy_localization/easy_localization.dart';
import '../../services/forum/forum_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String? initialCategory;

  const CreatePostScreen({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final ForumService _forumService = ForumService();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'general';
  List<File> _selectedImages = [];
  bool _isPosting = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'general', 'name': 'General', 'icon': Icons.chat_bubble_outline},
    {'id': 'help', 'name': 'Help', 'icon': Icons.help_outline},
    {'id': 'tips', 'name': 'Tips', 'icon': Icons.lightbulb_outline},
    {'id': 'news', 'name': 'News', 'icon': Icons.newspaper},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty && images.length + _selectedImages.length <= 5) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      } else if (images.length + _selectedImages.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('forum.max_images_error'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];

    for (var imageFile in _selectedImages) {
      try {
        // Read the image file
        final bytes = await imageFile.readAsBytes();

        // Decode and compress the image
        img.Image? image = img.decodeImage(bytes);
        if (image != null) {
          // Resize if too large (max width 1024px)
          if (image.width > 1024) {
            image = img.copyResize(image, width: 1024);
          }

          // Compress as JPEG with 85% quality
          final compressedBytes = img.encodeJpg(image, quality: 85);

          // Convert to base64
          final base64String = base64Encode(compressedBytes);
          base64Images.add('data:image/jpeg;base64,$base64String');
        }
      } catch (e) {
        print('Error converting image to base64: $e');
      }
    }

    return base64Images;
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('forum.empty_post_error'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      // Convert images to base64 first
      List<String> base64Images = [];
      if (_selectedImages.isNotEmpty) {
        base64Images = await _convertImagesToBase64();
      }

      // Create the post
      await _forumService.createPost(
        content: _contentController.text.trim(),
        imageUrls: base64Images,
        category: _selectedCategory,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('forum.post_created_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('forum.error_creating_post'.tr() + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF215C5C),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'common.create_post'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_isPosting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createPost,
              child: Text(
                'common.post'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category selection
              Text(
                'common.category'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['id'];
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'],
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF215C5C),
                        ),
                        const SizedBox(width: 6),
                        Text(cat['name']),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat['id'];
                        });
                      }
                    },
                    selectedColor: const Color(0xFF215C5C),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF215C5C),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Content input
              const Text(
                'What\'s on your mind?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 10,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText:
                      'common.share_your_thoughts_ask_questions_or_share_tips'
                          .tr(),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 24),

              // Image selection
              Row(
                children: [
                  Text(
                    'common.add_images'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _selectedImages.length < 5 ? _pickImages : null,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text('common.add'.tr()),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF215C5C),
                    ),
                  ),
                ],
              ),

              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Guidelines
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF008080),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF008080)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF215C5C),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'common.community_guidelines'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF215C5C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Be respectful and kind to others\n'
                      '• No spam or self-promotion\n'
                      '• Share helpful and relevant content\n'
                      '• Report inappropriate content',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
