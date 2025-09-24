import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Global service for handling image storage as base64 strings
/// This replaces Firebase Storage to avoid paid services
class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  /// Convert a File to base64 string
  Future<String> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Failed to convert file to base64: $e');
    }
  }

  /// Convert base64 string to bytes
  Uint8List base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      throw Exception('Failed to decode base64 string: $e');
    }
  }

  /// Create an Image widget from base64 string
  Widget base64ToImage(
    String base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    try {
      final bytes = base64ToBytes(base64String);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width ?? 100,
                height: height ?? 100,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      );
    } catch (e) {
      return errorWidget ??
          Container(
            width: width ?? 100,
            height: height ?? 100,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
    }
  }

  /// Get the size of a base64 image in bytes
  int getBase64Size(String base64String) {
    try {
      final bytes = base64ToBytes(base64String);
      return bytes.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if a base64 string is a valid image
  bool isValidBase64Image(String base64String) {
    try {
      final bytes = base64ToBytes(base64String);
      return bytes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Compress base64 image by reducing quality (for large images)
  /// This can help reduce Firestore document size
  Future<String> compressBase64Image(String base64String,
      {int quality = 80}) async {
    // For now, just return the original string
    // In the future, we could add image compression logic here
    return base64String;
  }

  /// Create a circular avatar from base64 string
  Widget base64ToCircularAvatar(
    String? base64String, {
    double radius = 20,
    Color backgroundColor = Colors.grey,
    Widget? child,
  }) {
    if (base64String == null || base64String.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: child ?? Icon(Icons.person, size: radius),
      );
    }

    try {
      final bytes = base64ToBytes(base64String);
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
        onBackgroundImageError: (exception, stackTrace) {
          // Handle error silently
        },
        child: null,
      );
    } catch (e) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: child ?? Icon(Icons.person, size: radius),
      );
    }
  }

  /// Create a placeholder image widget
  Widget createPlaceholder({
    double? width,
    double? height,
    IconData icon = Icons.image,
    Color backgroundColor = Colors.grey,
    Color iconColor = Colors.white,
  }) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Icon(
        icon,
        color: iconColor,
        size: (width != null && height != null) ? (width + height) / 6 : 40,
      ),
    );
  }
}
