import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageService {
  /// Maximum file size for Base64 encoding (800KB to stay within Firestore limits)
  static const int maxFileSizeBytes = 800000;

  /// Convert image file to Base64 data URL with compression if needed
  static Future<String> imageFileToBase64(File imageFile) async {
    try {
      // Read the original image
      final bytes = await imageFile.readAsBytes();

      // If image is already small enough, use it as is
      if (bytes.length <= maxFileSizeBytes) {
        final String base64Image = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64Image';
      }

      // Image is too large, need to compress
      final compressedBytes = await _compressImage(bytes);
      final String base64Image = base64Encode(compressedBytes);
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      throw Exception('Failed to convert image to Base64: $e');
    }
  }

  /// Compress image to fit within size limits
  static Future<Uint8List> _compressImage(Uint8List originalBytes) async {
    try {
      // Decode the image
      img.Image? decodedImage = img.decodeImage(originalBytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      // Work with non-nullable image
      img.Image image = decodedImage;

      // Start with quality 85 and reduce until file is small enough
      int quality = 85;
      Uint8List compressedBytes;

      do {
        // Resize if image is very large
        if (image.width > 1024 || image.height > 1024) {
          image = img.copyResize(
            image,
            width: image.width > image.height ? 1024 : null,
            height: image.height > image.width ? 1024 : null,
          );
        }

        // Encode with current quality
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: quality),
        );

        // Reduce quality for next iteration if still too large
        quality -= 10;

        // Prevent infinite loop
        if (quality < 20) break;
      } while (compressedBytes.length > maxFileSizeBytes);

      return compressedBytes;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Get image size information
  static Future<Map<String, dynamic>> getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Invalid image file');
      }

      return {
        'width': image.width,
        'height': image.height,
        'fileSize': bytes.length,
        'fileSizeKB': (bytes.length / 1024).round(),
        'fileSizeMB': (bytes.length / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Failed to get image info: $e');
    }
  }

  /// Create a temporary resized image file
  static Future<File> createResizedImage(
    File originalFile, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
  }) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Invalid image file');
      }

      // Resize image
      final resizedImage = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
      );

      // Encode to JPEG
      final resizedBytes = img.encodeJpg(resizedImage, quality: quality);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(resizedBytes);

      return tempFile;
    } catch (e) {
      throw Exception('Failed to create resized image: $e');
    }
  }

  /// Validate image file
  static Future<bool> isValidImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// Get optimal image dimensions for profile pictures
  static Map<String, int> getProfileImageDimensions() {
    return {
      'width': 400,
      'height': 400,
    };
  }

  /// Convert Base64 data URL back to image bytes
  static Uint8List base64ToBytes(String base64DataUrl) {
    try {
      // Remove the data URL prefix if present
      String base64Data = base64DataUrl;
      if (base64DataUrl.contains(',')) {
        base64Data = base64DataUrl.split(',')[1];
      }

      return base64Decode(base64Data);
    } catch (e) {
      throw Exception('Failed to decode Base64 image: $e');
    }
  }

  /// Create a circular cropped image widget from Base64 data
  static Widget buildCircularImageFromBase64(
    String base64DataUrl, {
    double size = 100,
    Widget? fallback,
  }) {
    try {
      final bytes = base64ToBytes(base64DataUrl);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      return fallback ??
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Icon(
              Icons.person,
              color: Colors.grey[400],
              size: size * 0.5,
            ),
          );
    }
  }
}
