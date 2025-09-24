import 'package:flutter/material.dart';

/// Mixin to provide consistent bottom padding calculations for screens
/// that need to avoid overlap with the custom bottom navigation bar
mixin BottomNavigationPaddingMixin {
  /// Calculate the bottom padding needed to avoid overlap with bottom navigation bar
  ///
  /// The main navigation has a custom bottom navigation bar with height:
  /// 85 + MediaQuery.viewPadding.bottom
  ///
  /// For content padding, we add an additional buffer (100) to ensure
  /// no content gets hidden behind the navigation bar
  double getBottomNavigationPadding(BuildContext context) {
    return MediaQuery.of(context).viewPadding.bottom + 100;
  }

  /// Get edge insets with bottom navigation padding
  EdgeInsets getEdgeInsetsWithBottomNavPadding(
    BuildContext context, {
    double? left,
    double? top,
    double? right,
    double additionalBottomPadding = 0,
  }) {
    return EdgeInsets.only(
      left: left ?? 20,
      top: top ?? 20,
      right: right ?? 20,
      bottom: getBottomNavigationPadding(context) + additionalBottomPadding,
    );
  }

  /// Get symmetric padding with bottom navigation consideration
  EdgeInsets getSymmetricPaddingWithBottomNav(
    BuildContext context, {
    double horizontal = 20,
    double vertical = 20,
    double additionalBottomPadding = 0,
  }) {
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal,
      top: vertical,
      bottom: getBottomNavigationPadding(context) + additionalBottomPadding,
    );
  }

  /// Widget to wrap content that needs bottom navigation padding
  Widget wrapWithBottomNavPadding(
    BuildContext context,
    Widget child, {
    double additionalPadding = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: getBottomNavigationPadding(context) + additionalPadding,
      ),
      child: child,
    );
  }
}
