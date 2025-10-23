import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/logging_service.dart';

/// 📊 Performance Monitoring Widget
/// Tracks screen load times and widget performance for optimization
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String screenName;
  final VoidCallback? onLoadComplete;

  const PerformanceMonitor({
    Key? key,
    required this.child,
    required this.screenName,
    this.onLoadComplete,
  }) : super(key: key);

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final Stopwatch _stopwatch = Stopwatch();
  final LoggingService _logger = LoggingService();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();

    // Track screen load time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopwatch.stop();

      _logger.logPerformance(
        operation: 'screen_load',
        duration: _stopwatch.elapsed,
        screen: widget.screenName,
        metadata: {
          'screen_name': widget.screenName,
          'load_time_ms': _stopwatch.elapsedMilliseconds,
        },
      );

      // Call completion callback
      widget.onLoadComplete?.call();

      // Log warning for slow loads
      if (_stopwatch.elapsedMilliseconds > 3000) {
        _logger.logEvent(
          event: LogEvent.performance,
          level: LogLevel.warning,
          message: 'Slow screen load detected: ${widget.screenName}',
          data: {
            'screen': widget.screenName,
            'load_time': _stopwatch.elapsedMilliseconds,
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 🎯 Performance tracking mixin for screens
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  final Stopwatch _screenStopwatch = Stopwatch();
  final LoggingService _logger = LoggingService();

  String get screenName => runtimeType.toString();

  @override
  void initState() {
    super.initState();
    _screenStopwatch.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackScreenLoad();
    });
  }

  void _trackScreenLoad() {
    _screenStopwatch.stop();

    _logger.logPerformance(
      operation: 'screen_initialize',
      duration: _screenStopwatch.elapsed,
      screen: screenName,
    );
  }

  /// Track async operations with performance metrics
  Future<R> trackAsyncOperation<R>(
    String operationName,
    Future<R> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      _logger.logPerformance(
        operation: operationName,
        duration: stopwatch.elapsed,
        screen: screenName,
        metadata: {
          'success': true,
          'screen': screenName,
          ...?metadata,
        },
      );

      return result;
    } catch (error) {
      stopwatch.stop();

      _logger.logPerformance(
        operation: '${operationName}_error',
        duration: stopwatch.elapsed,
        screen: screenName,
        metadata: {
          'success': false,
          'error': error.toString(),
          'screen': screenName,
          ...?metadata,
        },
      );

      rethrow;
    }
  }
}

/// 📱 Memory usage monitor for development
class MemoryMonitor extends StatefulWidget {
  final Widget child;

  const MemoryMonitor({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<MemoryMonitor> createState() => _MemoryMonitorState();
}

class _MemoryMonitorState extends State<MemoryMonitor> {
  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      // Monitor memory usage in debug mode
      SchedulerBinding.instance.addPersistentFrameCallback(_monitorMemory);
    }
  }

  void _monitorMemory(Duration timeStamp) {
    // This would typically integrate with platform channels
    // to get actual memory usage from the system

    // For now, we'll just log periodically in debug mode
    if (timeStamp.inSeconds % 30 == 0) {
      // Every 30 seconds
      LoggingService().logEvent(
        event: LogEvent.performance,
        level: LogLevel.info,
        message: 'common.memory_usage_checkpoint'.tr(),
        data: {
          'timestamp': timeStamp.inMilliseconds,
          'checkpoint': 'periodic_memory_check',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 🚀 Optimized list item builder for better performance
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollController? controller;
  final double? itemExtent;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final Widget? loadingWidget;

  const OptimizedListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.itemExtent,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.onLoadMore,
    this.hasMore = false,
    this.loadingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Load more when reaching the end
        if (hasMore &&
            onLoadMore != null &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        itemExtent: itemExtent,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,

        // Performance optimizations
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        cacheExtent: 500.0,

        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return loadingWidget ??
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
          }

          return RepaintBoundary(
            key: ValueKey(index),
            child: itemBuilder(context, items[index], index),
          );
        },
      ),
    );
  }
}

/// 🎨 Optimized image loading widget
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const OptimizedImage({
    Key? key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    Widget imageWidget = Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,

      // Performance optimizations
      cacheWidth: memCacheWidth ?? (width?.toInt()),
      cacheHeight: memCacheHeight ?? (height?.toInt()),

      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
      },

      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return RepaintBoundary(child: imageWidget);
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: errorWidget ??
          const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 32,
          ),
    );
  }
}

/// 🔄 Debouncer for search and other frequent operations
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// 📊 Performance tracking for animations
class AnimationPerformanceTracker {
  static final LoggingService _logger = LoggingService();

  static void trackAnimation({
    required String animationName,
    required Duration duration,
    String? screen,
    Map<String, dynamic>? metadata,
  }) {
    _logger.logPerformance(
      operation: 'animation_$animationName',
      duration: duration,
      screen: screen,
      metadata: {
        'animation_name': animationName,
        'is_long_animation': duration.inMilliseconds > 1000,
        ...?metadata,
      },
    );

    // Log warning for long animations
    if (duration.inMilliseconds > 1000) {
      _logger.logEvent(
        event: LogEvent.performance,
        level: LogLevel.warning,
        message: 'Long animation detected: $animationName',
        data: {
          'animation': animationName,
          'duration_ms': duration.inMilliseconds,
          'screen': screen,
        },
      );
    }
  }
}
