import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// 🎨 STATUS BAR UTILITIES
/// Universal status bar configuration for CrowdWave app
/// Implements solid blue background (matching home screen header) with white content across all screens
class StatusBarUtils {
  StatusBarUtils._();

  /// Universal status bar style configuration
  /// Uses solid blue (same as home screen header) with white content
  static const SystemUiOverlayStyle universalStatusBarStyle =
      SystemUiOverlayStyle(
    statusBarColor: AppColors
        .solidBlueStatusBar, // Solid blue background (same as home screen header)
    statusBarIconBrightness:
        Brightness.light, // White icons/text for better contrast on blue
    statusBarBrightness: Brightness.dark, // For iOS
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Apply universal status bar styling
  static void applyUniversalStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(universalStatusBarStyle);
  }

  /// Status bar wrapper widget to ensure consistent styling
  static Widget wrapWithStatusBar({required Widget child}) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: universalStatusBarStyle,
      child: child,
    );
  }
}

/// 🎨 UNIVERSAL STATUS BAR WRAPPER
/// Wrap any widget with this to apply universal solid blue status bar styling
class UniversalStatusBarWrapper extends StatelessWidget {
  final Widget child;

  const UniversalStatusBarWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: StatusBarUtils.universalStatusBarStyle,
      child: child,
    );
  }
}
