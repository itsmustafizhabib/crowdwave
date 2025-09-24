import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A custom pull-to-refresh widget that uses a liquid loader animation
/// with smooth pull and display timing controls
class LiquidRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;
  final double strokeWidth;
  final double animationSize;
  final Duration displayDuration;
  final Duration transitionDuration;
  // Minimum pull distance (overscroll) before we actually trigger a refresh.
  // Default is larger than stock RefreshIndicator (which is ~100) to reduce
  // accidental triggers from slight bounce / slow scroll up.
  final double triggerDistance;
  // Minimum time gap between two refresh executions to avoid repeated
  // triggering when user keeps slow-dragging near the top.
  final Duration minRefreshInterval;

  const LiquidRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.backgroundColor,
    this.strokeWidth = 2.0,
    this.animationSize = 60.0,
    this.displayDuration = const Duration(milliseconds: 1500),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.triggerDistance = 140.0,
    this.minRefreshInterval = const Duration(seconds: 3),
  });

  @override
  State<LiquidRefreshIndicator> createState() => _LiquidRefreshIndicatorState();
}

class _LiquidRefreshIndicatorState extends State<LiquidRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isRefreshing = false;
  bool _showAnimation = false;
  double _accumulatedOverscroll = 0.0;
  DateTime _lastRefreshTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  bool _canTriggerRefresh() {
    if (_isRefreshing) return false;
    final now = DateTime.now();
    if (now.difference(_lastRefreshTime) < widget.minRefreshInterval) {
      return false;
    }
    return true;
  }

  Future<void> _handleRefresh() async {
    if (!_canTriggerRefresh()) return;
    _lastRefreshTime = DateTime.now();

    setState(() {
      _isRefreshing = true;
      _showAnimation = true;
    });

    // Start entrance animations (animation comes down)
    _fadeController.forward();
    _scaleController.forward();

    try {
      // Start the actual refresh after 1 second (so it completes by animation end)
      Future.delayed(const Duration(milliseconds: 1000), () async {
        await widget.onRefresh();
      });

      // Show the animation for 1.5 seconds total
      await Future.delayed(const Duration(milliseconds: 1500));

      // Start exit animations (animation goes back up)
      await _fadeController.reverse();
      await _scaleController.reverse();
    } catch (error) {
      // Handle any errors from the refresh operation
      debugPrint('Refresh error: $error');
    } finally {
      setState(() {
        _isRefreshing = false;
        _showAnimation = false;
      });

      // Reset controllers for next use
      _fadeController.reset();
      _scaleController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Track overscroll distance manually to decide whether to allow refresh.
        if (notification is OverscrollNotification) {
          if (notification.overscroll < 0) {
            // User is pulling down.
            _accumulatedOverscroll += -notification.overscroll;
          }
        } else if (notification is ScrollEndNotification ||
            notification is ScrollUpdateNotification) {
          // If user scrolls back up (positive pixels) or ends scroll
          // without reaching trigger, reset.
          if (notification.metrics.pixels > 0 ||
              _accumulatedOverscroll < widget.triggerDistance) {
            // Do nothing special; just ensure we don't keep old value.
          }
        }
        return false; // allow bubbling
      },
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              // Only proceed if overscroll exceeded threshold.
              if (_accumulatedOverscroll >= widget.triggerDistance) {
                await _handleRefresh();
              }
              // Always reset the accumulator after an attempted refresh.
              _accumulatedOverscroll = 0.0;
            },
            backgroundColor: Colors.transparent,
            color: Colors.transparent,
            strokeWidth: 0,
            displacement: 0,
            notificationPredicate: (notification) {
              // Allow refresh only when at top and we have pulled sufficiently.
              final shouldAllow = notification.metrics.pixels <= 0;
              if (!shouldAllow) {
                _accumulatedOverscroll = 0.0; // reset if not at top anymore
              }
              return shouldAllow;
            },
            child: widget.child,
          ),
          if (_showAnimation)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
                builder: (context, child) {
                  return Center(
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: widget.animationSize,
                          height: widget.animationSize,
                          decoration: BoxDecoration(
                            color: widget.backgroundColor ??
                                Theme.of(context)
                                    .scaffoldBackgroundColor
                                    .withOpacity(0.95),
                            borderRadius:
                                BorderRadius.circular(widget.animationSize / 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Lottie.asset(
                              'assets/animations/liquid loader 01.json',
                              width: widget.animationSize - 16,
                              height: widget.animationSize - 16,
                              fit: BoxFit.contain,
                              repeat: true,
                              animate: _isRefreshing,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Enhanced version with pull distance feedback
class LiquidRefreshIndicatorWithFeedback extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;
  final double animationSize;
  final Duration displayDuration;
  final Duration transitionDuration;
  final double triggerDistance;

  const LiquidRefreshIndicatorWithFeedback({
    super.key,
    required this.child,
    required this.onRefresh,
    this.backgroundColor,
    this.animationSize = 60.0,
    this.displayDuration = const Duration(milliseconds: 1500),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.triggerDistance = 80.0,
  });

  @override
  State<LiquidRefreshIndicatorWithFeedback> createState() =>
      _LiquidRefreshIndicatorWithFeedbackState();
}

class _LiquidRefreshIndicatorWithFeedbackState
    extends State<LiquidRefreshIndicatorWithFeedback>
    with TickerProviderStateMixin {
  late AnimationController _pullController;
  late AnimationController _refreshController;
  late Animation<double> _pullAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isRefreshing = false;
  bool _showPullIndicator = false;

  @override
  void initState() {
    super.initState();

    _pullController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _refreshController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    _pullAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pullController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pullController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _showPullIndicator = false;
    });

    // Start refresh animations (animation comes down)
    _refreshController.forward();

    try {
      // Start the actual refresh after 1 second (so it completes by animation end)
      Future.delayed(const Duration(milliseconds: 1000), () async {
        await widget.onRefresh();
      });

      // Show the animation for 1.5 seconds total
      await Future.delayed(const Duration(milliseconds: 1500));

      // Start exit animations (animation goes back up)
      await _refreshController.reverse();
    } catch (error) {
      debugPrint('Refresh error: $error');
    } finally {
      setState(() {
        _isRefreshing = false;
      });

      _refreshController.reset();
      _pullController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels < -20 && !_isRefreshing) {
                final distance = (-notification.metrics.pixels - 20)
                    .clamp(0.0, widget.triggerDistance);

                if (distance > 0 && !_showPullIndicator) {
                  setState(() {
                    _showPullIndicator = true;
                  });
                  _pullController.forward();
                }

                final progress =
                    (distance / widget.triggerDistance).clamp(0.0, 1.0);
                _pullController.value = progress;
              } else if (notification.metrics.pixels >= -20 &&
                  _showPullIndicator) {
                setState(() {
                  _showPullIndicator = false;
                });
                _pullController.reverse();
              }
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            backgroundColor: Colors.transparent,
            color: Colors.transparent,
            strokeWidth: 0,
            displacement: widget.animationSize + 20,
            child: widget.child,
          ),
        ),
        if (_showPullIndicator && !_isRefreshing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _pullAnimation,
              builder: (context, child) {
                return Center(
                  child: Opacity(
                    opacity: _pullAnimation.value * 0.8,
                    child: Transform.scale(
                      scale: 0.3 + (_pullAnimation.value * 0.7),
                      child: Container(
                        width: widget.animationSize * 0.8,
                        height: widget.animationSize * 0.8,
                        decoration: BoxDecoration(
                          color: widget.backgroundColor ??
                              Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withOpacity(0.9),
                          borderRadius:
                              BorderRadius.circular(widget.animationSize / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Lottie.asset(
                            'assets/animations/liquid loader 01.json',
                            fit: BoxFit.contain,
                            repeat: false,
                            animate: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_isRefreshing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Center(
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: widget.animationSize,
                        height: widget.animationSize,
                        decoration: BoxDecoration(
                          color: widget.backgroundColor ??
                              Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withOpacity(0.95),
                          borderRadius:
                              BorderRadius.circular(widget.animationSize / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Lottie.asset(
                            'assets/animations/liquid loader 01.json',
                            width: widget.animationSize - 16,
                            height: widget.animationSize - 16,
                            fit: BoxFit.contain,
                            repeat: true,
                            animate: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
