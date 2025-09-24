import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EnhancedCardWidget extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableHoverEffect;
  final double? elevation;
  final Gradient? gradient;

  const EnhancedCardWidget({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.shadows,
    this.borderRadius,
    this.onTap,
    this.enableHoverEffect = true,
    this.elevation,
    this.gradient,
  }) : super(key: key);

  @override
  State<EnhancedCardWidget> createState() => _EnhancedCardWidgetState();
}

class _EnhancedCardWidgetState extends State<EnhancedCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enableHoverEffect) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enableHoverEffect) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enableHoverEffect) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin ?? EdgeInsets.symmetric(vertical: 1.h),
            child: Material(
              elevation: widget.elevation != null 
                  ? widget.elevation! * _shadowAnimation.value
                  : 4.0 * _shadowAnimation.value,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              color: Colors.transparent,
              shadowColor: Colors.black.withOpacity(0.1),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onTap,
                child: Container(
                  padding: widget.padding ?? EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? Colors.white,
                    gradient: widget.gradient,
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                    boxShadow: widget.shadows ?? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GradientCardWidget extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientCardWidget({
    Key? key,
    required this.child,
    required this.gradientColors,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedCardWidget(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      gradient: LinearGradient(
        colors: gradientColors,
        begin: begin,
        end: end,
      ),
      child: child,
    );
  }
}

class GlassMorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double opacity;
  final double blur;

  const GlassMorphismCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.opacity = 0.1,
    this.blur = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnhancedCardWidget(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      backgroundColor: Colors.white.withOpacity(opacity),
      elevation: 0,
      shadows: [
        BoxShadow(
          color: Colors.white.withOpacity(0.2),
          blurRadius: blur,
          offset: const Offset(0, 0),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}
