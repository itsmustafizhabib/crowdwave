import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ConfettiCelebrationWidget extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final bool autoPlay;
  final Duration duration;
  final bool repeat;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ConfettiCelebrationWidget({
    Key? key,
    this.onAnimationComplete,
    this.autoPlay = true,
    this.duration = const Duration(milliseconds: 2000),
    this.repeat = false,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<ConfettiCelebrationWidget> createState() => _ConfettiCelebrationWidgetState();
}

class _ConfettiCelebrationWidgetState extends State<ConfettiCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

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

    if (widget.autoPlay) {
      _playAnimation();
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  void _playAnimation() {
    _controller.forward();
  }

  void play() {
    _playAnimation();
  }

  void stop() {
    _controller.stop();
  }

  void reset() {
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Lottie.asset(
            'assets/animations/Confetti.json',
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            repeat: widget.repeat,
            controller: _controller,
          ),
        );
      },
    );
  }
}

// Overlay version for full-screen celebrations
class ConfettiOverlay extends StatelessWidget {
  final VoidCallback? onComplete;
  final Duration duration;
  final bool autoPlay;

  const ConfettiOverlay({
    Key? key,
    this.onComplete,
    this.duration = const Duration(milliseconds: 2000),
    this.autoPlay = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ConfettiCelebrationWidget(
        onAnimationComplete: onComplete,
        duration: duration,
        autoPlay: autoPlay,
        repeat: false,
        fit: BoxFit.cover,
      ),
    );
  }
}

// Trigger confetti celebration anywhere in the app
class ConfettiTrigger {
  static void showConfetti(
    BuildContext context, {
    Duration duration = const Duration(milliseconds: 2000),
    VoidCallback? onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: ConfettiCelebrationWidget(
          duration: duration,
          onAnimationComplete: () {
            Navigator.of(context).pop();
            onComplete?.call();
          },
        ),
      ),
    );
  }

  static void showConfettiOverlay(
    BuildContext context, {
    Duration duration = const Duration(milliseconds: 2000),
    VoidCallback? onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: ConfettiOverlay(
          duration: duration,
          onComplete: () {
            Navigator.of(context).pop();
            onComplete?.call();
          },
        ),
      ),
    );
  }
}
