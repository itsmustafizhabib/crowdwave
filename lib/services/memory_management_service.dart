import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 🧹 MEMORY MANAGEMENT SERVICE
///
/// Handles systematic memory cleanup to prevent black screen issues
/// caused by memory pressure and resource leaks.
///
/// Key Features:
/// 1. Periodic memory cleanup
/// 2. Stream subscription management
/// 3. Image cache optimization
/// 4. Widget lifecycle monitoring

class MemoryManagementService extends GetxService {
  static MemoryManagementService get to => Get.find();

  // Cleanup timers
  Timer? _periodicCleanupTimer;
  Timer? _aggressiveCleanupTimer;

  // Memory monitoring
  final RxInt _activeStreams = 0.obs;
  final RxInt _activeControllers = 0.obs;
  final RxDouble _memoryPressure = 0.0.obs;

  // Subscription tracking
  final Set<StreamSubscription> _trackedSubscriptions = {};
  final Set<AnimationController> _trackedControllers = {};

  // Configuration
  static const Duration _periodicInterval = Duration(minutes: 5);
  static const Duration _aggressiveInterval = Duration(minutes: 10);
  static const int _maxImageCacheSize = 50; // MB
  static const int _maxActiveStreams = 20;

  @override
  void onInit() {
    super.onInit();
    _startMemoryManagement();
  }

  @override
  void onClose() {
    _stopMemoryManagement();
    super.onClose();
  }

  /// Start memory management system
  void _startMemoryManagement() {
    if (kDebugMode) {
      print('🧹 MemoryManagementService: Starting memory management...');
    }

    // Periodic lightweight cleanup
    _periodicCleanupTimer = Timer.periodic(_periodicInterval, (_) {
      _performPeriodicCleanup();
    });

    // Aggressive cleanup for memory pressure
    _aggressiveCleanupTimer = Timer.periodic(_aggressiveInterval, (_) {
      _performAggressiveCleanup();
    });

    // Configure image cache
    _configureImageCache();
  }

  /// Stop memory management system
  void _stopMemoryManagement() {
    _periodicCleanupTimer?.cancel();
    _aggressiveCleanupTimer?.cancel();

    // Clean up tracked resources
    _cleanupTrackedResources();
  }

  /// Configure image cache for optimal memory usage
  void _configureImageCache() {
    imageCache.maximumSize = 100; // Limit cached images
    imageCache.maximumSizeBytes = _maxImageCacheSize * 1024 * 1024; // 50MB

    if (kDebugMode) {
      print('📸 Image cache configured: max ${_maxImageCacheSize}MB');
    }
  }

  /// Perform periodic lightweight cleanup
  void _performPeriodicCleanup() {
    try {
      if (kDebugMode) {
        print('🧹 Performing periodic cleanup...');
        print('📊 Active streams: ${_activeStreams.value}');
        print('📊 Active controllers: ${_activeControllers.value}');
      }

      // Clean up image cache if it's getting large
      if (imageCache.currentSizeBytes > (imageCache.maximumSizeBytes * 0.8)) {
        _cleanupImageCache();
      }

      // Remove completed/disposed subscriptions
      _cleanupDeadSubscriptions();

      // Remove disposed controllers
      _cleanupDeadControllers();

      if (kDebugMode) {
        print('✅ Periodic cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Periodic cleanup error: $e');
      }
    }
  }

  /// Perform aggressive cleanup for memory pressure
  void _performAggressiveCleanup() {
    try {
      if (kDebugMode) {
        print('🚨 Performing aggressive cleanup...');
      }

      // Force image cache cleanup
      _cleanupImageCache();

      // Force dispose inactive resources
      _forceCleanupInactiveResources();

      // Trigger garbage collection hint
      _triggerGarbageCollection();

      if (kDebugMode) {
        print('✅ Aggressive cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Aggressive cleanup error: $e');
      }
    }
  }

  /// Clean up image cache
  void _cleanupImageCache() {
    final sizeBefore = imageCache.currentSizeBytes;
    imageCache.clear();
    imageCache.clearLiveImages();

    if (kDebugMode) {
      print('📸 Image cache cleared: ${sizeBefore ~/ 1024}KB freed');
    }
  }

  /// Clean up dead subscriptions
  void _cleanupDeadSubscriptions() {
    final deadSubscriptions =
        _trackedSubscriptions.where((sub) => sub.isPaused).toList();

    for (final sub in deadSubscriptions) {
      _trackedSubscriptions.remove(sub);
      _activeStreams.value = _trackedSubscriptions.length;
    }

    if (deadSubscriptions.isNotEmpty && kDebugMode) {
      print('🗑️ Removed ${deadSubscriptions.length} dead subscriptions');
    }
  }

  /// Clean up dead controllers
  void _cleanupDeadControllers() {
    final deadControllers = _trackedControllers
        .where((controller) => controller.isCompleted || controller.isDismissed)
        .toList();

    for (final controller in deadControllers) {
      _trackedControllers.remove(controller);
      _activeControllers.value = _trackedControllers.length;
    }

    if (deadControllers.isNotEmpty && kDebugMode) {
      print('🗑️ Removed ${deadControllers.length} dead controllers');
    }
  }

  /// Force cleanup inactive resources
  void _forceCleanupInactiveResources() {
    // Cancel all tracked subscriptions if too many
    if (_trackedSubscriptions.length > _maxActiveStreams) {
      final excessCount = _trackedSubscriptions.length - _maxActiveStreams;
      final toRemove = _trackedSubscriptions.take(excessCount).toList();

      for (final sub in toRemove) {
        try {
          sub.cancel();
          _trackedSubscriptions.remove(sub);
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error canceling subscription: $e');
          }
        }
      }

      _activeStreams.value = _trackedSubscriptions.length;

      if (kDebugMode) {
        print('🚨 Force canceled $excessCount excess subscriptions');
      }
    }
  }

  /// Trigger garbage collection hint
  void _triggerGarbageCollection() {
    // Force rebuild to trigger potential garbage collection
    WidgetsBinding.instance.reassembleApplication();
  }

  /// Clean up all tracked resources
  void _cleanupTrackedResources() {
    try {
      // Cancel all subscriptions
      for (final sub in _trackedSubscriptions) {
        try {
          sub.cancel();
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error canceling subscription during cleanup: $e');
          }
        }
      }
      _trackedSubscriptions.clear();

      // Dispose all controllers
      for (final controller in _trackedControllers) {
        try {
          if (!controller.isCompleted && !controller.isDismissed) {
            controller.dispose();
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error disposing controller during cleanup: $e');
          }
        }
      }
      _trackedControllers.clear();

      _activeStreams.value = 0;
      _activeControllers.value = 0;

      if (kDebugMode) {
        print('✅ All tracked resources cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during resource cleanup: $e');
      }
    }
  }

  /// Track a stream subscription for automatic cleanup
  void trackSubscription(StreamSubscription subscription) {
    _trackedSubscriptions.add(subscription);
    _activeStreams.value = _trackedSubscriptions.length;

    if (kDebugMode) {
      print('📡 Tracking new subscription (total: ${_activeStreams.value})');
    }
  }

  /// Track an animation controller for automatic cleanup
  void trackController(AnimationController controller) {
    _trackedControllers.add(controller);
    _activeControllers.value = _trackedControllers.length;

    if (kDebugMode) {
      print('🎬 Tracking new controller (total: ${_activeControllers.value})');
    }
  }

  /// Untrack a subscription (when manually disposed)
  void untrackSubscription(StreamSubscription subscription) {
    if (_trackedSubscriptions.remove(subscription)) {
      _activeStreams.value = _trackedSubscriptions.length;

      if (kDebugMode) {
        print('📡 Untracked subscription (total: ${_activeStreams.value})');
      }
    }
  }

  /// Untrack a controller (when manually disposed)
  void untrackController(AnimationController controller) {
    if (_trackedControllers.remove(controller)) {
      _activeControllers.value = _trackedControllers.length;

      if (kDebugMode) {
        print('🎬 Untracked controller (total: ${_activeControllers.value})');
      }
    }
  }

  /// Force immediate cleanup (for emergency situations)
  void forceCleanup() {
    if (kDebugMode) {
      print('🚨 FORCE CLEANUP: Emergency memory cleanup initiated');
    }

    _performAggressiveCleanup();
    _cleanupTrackedResources();

    // Reinitialize tracking
    _activeStreams.value = 0;
    _activeControllers.value = 0;

    if (kDebugMode) {
      print('✅ FORCE CLEANUP: Emergency cleanup completed');
    }
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'activeStreams': _activeStreams.value,
      'activeControllers': _activeControllers.value,
      'imageCacheSizeBytes': imageCache.currentSizeBytes,
      'imageCacheSizeMB':
          (imageCache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'imageCacheCount': imageCache.currentSize,
      'memoryPressure': _memoryPressure.value,
    };
  }

  /// Check if system is under memory pressure
  bool isUnderMemoryPressure() {
    return _activeStreams.value > _maxActiveStreams ||
        imageCache.currentSizeBytes > (imageCache.maximumSizeBytes * 0.9);
  }
}
