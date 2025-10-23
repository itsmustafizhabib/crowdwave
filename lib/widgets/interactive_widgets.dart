import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CarouselWidget extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool enlargeCenterPage;
  final double viewportFraction;
  final Function(int)? onPageChanged;
  final bool enableInfiniteScroll;
  final Axis scrollDirection;

  const CarouselWidget({
    Key? key,
    required this.items,
    this.height = 200,
    this.padding,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.enlargeCenterPage = true,
    this.viewportFraction = 0.8,
    this.onPageChanged,
    this.enableInfiniteScroll = true,
    this.scrollDirection = Axis.horizontal,
  }) : super(key: key);

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: widget.enableInfiniteScroll ? 1000 : 0,
    );

    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (mounted) {
        _nextPage();
        _startAutoPlay();
      }
    });
  }

  void _nextPage() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getRealIndex(int index) {
    if (widget.enableInfiniteScroll) {
      return index % widget.items.length;
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: widget.scrollDirection,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = _getRealIndex(index);
              });
              if (widget.onPageChanged != null) {
                widget.onPageChanged!(_currentIndex);
              }
            },
            itemCount: widget.enableInfiniteScroll ? null : widget.items.length,
            itemBuilder: (context, index) {
              final realIndex = _getRealIndex(index);
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }

                  return Center(
                    child: SizedBox(
                      height: widget.enlargeCenterPage
                          ? Curves.easeOut.transform(value) * widget.height
                          : widget.height,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  child: widget.items[realIndex],
                ),
              );
            },
          ),
        ),
        if (widget.items.length > 1) ...[
          SizedBox(height: 2.h),
          _buildIndicators(),
        ],
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.items.asMap().entries.map((entry) {
        int index = entry.key;
        bool isActive = index == _currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          width: isActive ? 6.w : 2.w,
          height: 2.w,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2D7A6E)
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1.w),
          ),
        );
      }).toList(),
    );
  }
}

class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onTap;
  final double swipeThreshold;
  final Duration animationDuration;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const SwipeableCard({
    Key? key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTap,
    this.swipeThreshold = 0.3,
    this.animationDuration = const Duration(milliseconds: 300),
    this.margin,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final swipeDistance = _dragOffset.dx.abs();
    final swipeVelocity = details.velocity.pixelsPerSecond.dx.abs();

    if (swipeDistance > screenWidth * widget.swipeThreshold ||
        swipeVelocity > 1000) {
      // Complete the swipe
      _completeSwipe(_dragOffset.dx > 0);
    } else {
      // Return to original position
      _resetPosition();
    }
  }

  void _completeSwipe(bool isRightSwipe) {
    final screenWidth = MediaQuery.of(context).size.width;
    final endOffset = Offset(
      isRightSwipe ? screenWidth : -screenWidth,
      _dragOffset.dy,
    );

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _dragOffset.dx * 0.001,
      end: isRightSwipe ? 0.3 : -0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward().then((_) {
      if (isRightSwipe && widget.onSwipeRight != null) {
        widget.onSwipeRight!();
      } else if (!isRightSwipe && widget.onSwipeLeft != null) {
        widget.onSwipeLeft!();
      }
      _resetCard();
    });
  }

  void _resetPosition() {
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _dragOffset.dx * 0.001,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward().then((_) {
      _resetCard();
    });
  }

  void _resetCard() {
    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final offset = _isDragging && _animationController.value == 0
              ? _dragOffset
              : _slideAnimation.value;

          final rotation = _isDragging && _animationController.value == 0
              ? _dragOffset.dx * 0.001
              : _rotationAnimation.value;

          return Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: _animationController.isAnimating
                    ? _scaleAnimation.value
                    : 1.0,
                child: Opacity(
                  opacity: _animationController.isAnimating
                      ? _opacityAnimation.value
                      : 1.0,
                  child: Container(
                    margin: widget.margin ?? EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      borderRadius:
                          widget.borderRadius ?? BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          widget.borderRadius ?? BorderRadius.circular(16),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ParallaxWidget extends StatefulWidget {
  final Widget child;
  final double parallaxOffset;
  final Axis direction;

  const ParallaxWidget({
    Key? key,
    required this.child,
    this.parallaxOffset = 0.5,
    this.direction = Axis.vertical,
  }) : super(key: key);

  @override
  State<ParallaxWidget> createState() => _ParallaxWidgetState();
}

class _ParallaxWidgetState extends State<ParallaxWidget> {
  final GlobalKey _widgetKey = GlobalKey();
  double _offset = 0.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_widgetKey.currentContext != null) {
          final RenderBox renderBox =
              _widgetKey.currentContext!.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);

          final screenHeight = MediaQuery.of(context).size.height;
          final itemPosition = position.dy;
          final itemHeight = renderBox.size.height;

          if (itemPosition < screenHeight && itemPosition + itemHeight > 0) {
            setState(() {
              _offset =
                  (screenHeight / 2 - itemPosition) * widget.parallaxOffset;
            });
          }
        }
        return false;
      },
      child: Transform.translate(
        key: _widgetKey,
        offset: widget.direction == Axis.vertical
            ? Offset(0, _offset)
            : Offset(_offset, 0),
        child: widget.child,
      ),
    );
  }
}
