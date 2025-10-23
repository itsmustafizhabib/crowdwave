import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Gradient? gradient;
  final AnimatedButtonType type;
  final double? width;
  final double? height;

  const AnimatedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.borderRadius,
    this.padding,
    this.elevation,
    this.gradient,
    this.type = AnimatedButtonType.elevated,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

enum AnimatedButtonType { elevated, outlined, gradient, glass }

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: _buildButton(),
          ),
        );
      },
    );
  }

  Widget _buildButton() {
    switch (widget.type) {
      case AnimatedButtonType.elevated:
        return _buildElevatedButton();
      case AnimatedButtonType.outlined:
        return _buildOutlinedButton();
      case AnimatedButtonType.gradient:
        return _buildGradientButton();
      case AnimatedButtonType.glass:
        return _buildGlassButton();
    }
  }

  Widget _buildElevatedButton() {
    return Container(
      width: widget.width,
      height: widget.height ?? 6.h,
      child: ElevatedButton(
        onPressed: widget.isLoading
            ? null
            : () {
                print(
                    '🔥 AnimatedButton onPressed called! isLoading: ${widget.isLoading}');
                widget.onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? const Color(0xFF2D7A6E),
          foregroundColor: widget.textColor ?? Colors.white,
          elevation: widget.elevation ?? 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          ),
          padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 6.w),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    return Container(
      width: widget.width,
      height: widget.height ?? 6.h,
      child: OutlinedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.textColor ?? const Color(0xFF2D7A6E),
          side: BorderSide(
            color: widget.backgroundColor ?? const Color(0xFF2D7A6E),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          ),
          padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 6.w),
        ),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: Container(
        width: widget.width,
        height: widget.height ?? 6.h,
        decoration: BoxDecoration(
          gradient: widget.gradient ??
              LinearGradient(
                colors: [
                  const Color(0xFF2D7A6E),
                  const Color(0xFF215C5C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            child: Container(
              padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 6.w),
              child: _buildButtonContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: Container(
        width: widget.width,
        height: widget.height ?? 6.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            child: Container(
              padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 6.w),
              child: _buildButtonContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 4.w,
          height: 4.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.textColor ?? Colors.white,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 5.w,
            color: widget.textColor ?? Colors.white,
          ),
          SizedBox(width: 2.w),
        ],
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: widget.textColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

class FloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? heroTag;
  final double? size;
  final bool mini;
  final List<Color>? gradientColors;

  const FloatingActionButton({
    Key? key,
    this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.heroTag,
    this.size,
    this.mini = false,
    this.gradientColors,
  }) : super(key: key);

  @override
  State<FloatingActionButton> createState() => _FloatingActionButtonState();
}

class _FloatingActionButtonState extends State<FloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _controller.forward();
  }

  void _onTapUp() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => _onTapDown(),
              onTapUp: (_) => _onTapUp(),
              onTapCancel: () => _onTapUp(),
              child: Container(
                width: widget.size ?? (widget.mini ? 10.w : 14.w),
                height: widget.size ?? (widget.mini ? 10.w : 14.w),
                decoration: BoxDecoration(
                  gradient: widget.gradientColors != null
                      ? LinearGradient(
                          colors: widget.gradientColors!,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.gradientColors == null
                      ? (widget.backgroundColor ?? const Color(0xFF2D7A6E))
                      : null,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: widget.onPressed,
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor ?? Colors.white,
                        size: widget.mini ? 5.w : 6.w,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
