import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/animation_preload_service.dart';

class LoadingAnimationWidget extends StatefulWidget {
  final double size;
  final bool repeat;
  final Duration duration;
  final BoxFit fit;
  final VoidCallback? onAnimationComplete;

  const LoadingAnimationWidget({
    Key? key,
    this.size = 50.0,
    this.repeat = true,
    this.duration = const Duration(milliseconds: 2000),
    this.fit = BoxFit.contain,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<LoadingAnimationWidget> createState() => _LoadingAnimationWidgetState();
}

class _LoadingAnimationWidgetState extends State<LoadingAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final AnimationPreloadService _animationService = AnimationPreloadService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const loadingAnimationPath = 'assets/animations/Loading-animation.json';
    final preloadedComposition =
        _animationService.getPreloadedAnimation(loadingAnimationPath);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            child: preloadedComposition != null
                ? Lottie(
                    composition: preloadedComposition,
                    fit: widget.fit,
                    repeat: widget.repeat,
                    controller: _controller,
                  )
                : Lottie.asset(
                    loadingAnimationPath,
                    fit: widget.fit,
                    repeat: widget.repeat,
                    controller: _controller,
                  ),
          ),
        );
      },
    );
  }
}

// Full-screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Color? textColor;
  final double animationSize;

  const LoadingOverlay({
    Key? key,
    this.message,
    this.backgroundColor,
    this.textColor,
    this.animationSize = 80.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget(
              size: animationSize,
              repeat: true,
            ),
            if (message != null) ...[
              SizedBox(height: 20),
              Text(
                message!,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Loading button with animation
class LoadingButton extends StatefulWidget {
  final String text;
  final String loadingText;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double animationSize;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LoadingButton({
    Key? key,
    required this.text,
    this.loadingText = 'Loading...',
    this.onPressed,
    this.isLoading = false,
    this.animationSize = 20.0,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 48.0,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              widget.backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: widget.textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
          ),
        ),
        child: widget.isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget(
                    size: widget.animationSize,
                    repeat: true,
                  ),
                  SizedBox(width: 12),
                  Text(widget.loadingText),
                ],
              )
            : Text(widget.text),
      ),
    );
  }
}

// Loading card with animation
class LoadingCard extends StatelessWidget {
  final double animationSize;
  final String? message;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const LoadingCard({
    Key? key,
    this.animationSize = 60.0,
    this.message,
    this.backgroundColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? Colors.white,
      child: Padding(
        padding: padding ?? EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationWidget(
              size: animationSize,
              repeat: true,
            ),
            if (message != null) ...[
              SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
