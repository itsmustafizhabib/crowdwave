import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class PerformanceConfig {
  // Enable performance monitoring
  static const bool enablePerformanceMonitoring = kDebugMode;

  // Optimize image cache size
  static const int imageCacheSize = 100; // Number of images to cache
  static const int imageCacheSizeBytes = 50 * 1024 * 1024; // 50MB cache

  // Optimize list view settings
  static const int listViewCacheExtent =
      250; // Pixels to cache outside viewport

  // Optimize animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 200);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Optimize Firestore settings
  static const int firestoreTimeout = 10000; // 10 seconds
  static const int firestoreCacheSize = 40 * 1024 * 1024; // 40MB

  // Configure debounce timers for search and input
  static const Duration searchDebounceTime = Duration(milliseconds: 300);
  static const Duration inputDebounceTime = Duration(milliseconds: 150);

  // Memory management
  static const int maxNotificationCacheSize = 100;
  static const int maxChatMessageCacheSize = 200;

  /// Initialize performance optimizations
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('🚀 Initializing performance optimizations...');
    }

    // Optimize system UI
    await _optimizeSystemUI();

    // Set up memory management
    _setupMemoryManagement();

    if (kDebugMode) {
      print('✅ Performance optimizations initialized');
    }
  }

  static Future<void> _optimizeSystemUI() async {
    // Reduce GPU overdraw by setting transparent navigation
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );
    }
  }

  static void _setupMemoryManagement() {
    // Configure image cache
    PaintingBinding.instance.imageCache.maximumSize = imageCacheSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = imageCacheSizeBytes;

    if (kDebugMode) {
      print(
          '📱 Image cache configured: $imageCacheSize images, ${imageCacheSizeBytes ~/ (1024 * 1024)}MB');
    }
  }

  /// Clear caches to free memory
  static void clearCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    if (kDebugMode) {
      print('🧹 Caches cleared');
    }
  }

  /// Get optimized ListView physics
  static ScrollPhysics getOptimizedScrollPhysics() {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  /// Get optimized list view cache extent
  static double getListViewCacheExtent() {
    return listViewCacheExtent.toDouble();
  }
}
