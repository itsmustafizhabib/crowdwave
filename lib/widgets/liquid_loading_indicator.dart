import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LiquidLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final bool animate;
  final String? text;
  final TextStyle? textStyle;

  const LiquidLoadingIndicator({
    super.key,
    this.size = 60.0,
    this.color,
    this.animate = true,
    this.text,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    Widget loadingWidget = Container(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/liquid loader 01.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
        animate: animate,
        repeat: animate,
      ),
    );

    // If color is specified, wrap with ColorFiltered
    if (color != null) {
      loadingWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          color!,
          BlendMode.srcATop,
        ),
        child: loadingWidget,
      );
    }

    // If text is provided, show it below the animation
    if (text != null && text!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingWidget,
          const SizedBox(height: 8),
          Text(
            text!,
            style: textStyle ??
                const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
          ),
        ],
      );
    }

    return loadingWidget;
  }
}

// Convenience widget for centered loading with optional background
class CenteredLiquidLoading extends StatelessWidget {
  final double size;
  final Color? color;
  final String? text;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final bool showBackground;

  const CenteredLiquidLoading({
    super.key,
    this.size = 80.0,
    this.color,
    this.text,
    this.textStyle,
    this.backgroundColor,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: LiquidLoadingIndicator(
        size: size,
        color: color,
        text: text,
        textStyle: textStyle,
      ),
    );

    if (showBackground) {
      content = Container(
        color: backgroundColor ?? Colors.black.withOpacity(0.1),
        child: content,
      );
    }

    return content;
  }
}

// Small loading indicator for buttons and inline use
class SmallLiquidLoading extends StatelessWidget {
  final Color? color;

  const SmallLiquidLoading({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidLoadingIndicator(
      size: 20.0,
      color: color ?? Colors.white,
    );
  }
}
