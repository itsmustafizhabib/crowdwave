import 'package:flutter/material.dart';
import '../widgets/liquid_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  /// Optional widget to show when the image fails to load.
  /// If null, a default asset image is shown.
  final Widget? errorWidget;

  const CustomImageWidget({
    Key? key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle null or empty imageUrl
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackWidget();
    }

    // Check if the image is Base64 encoded (starts with data:image/)
    if (imageUrl!.startsWith('data:image/')) {
      try {
        // Extract Base64 data from the data URL
        final base64Data = imageUrl!.split(',')[1];
        final bytes = base64Decode(base64Data);

        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackWidget();
          },
        );
      } catch (e) {
        // If Base64 decoding fails, show fallback
        return _buildFallbackWidget();
      }
    }

    // Handle regular network URLs
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      errorWidget: (context, url, error) => _buildFallbackWidget(),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: LiquidLoadingIndicator(),
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person,
            color: Colors.grey[400],
            size: width * 0.5,
          ),
        );
  }
}
