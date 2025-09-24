import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that provides consistent immersive experience
/// across all screens with transparent navigation bar support
class ImmersiveScreenWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  const ImmersiveScreenWrapper({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.extendBodyBehindAppBar = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure transparent navigation bar for this screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: SafeArea(
        top: safeAreaTop,
        bottom: safeAreaBottom,
        child: child,
      ),
    );
  }
}

/// A wrapper for screens that need bottom padding for navigation bar area
class ImmersiveScreenWithBottomPadding extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double additionalBottomPadding;

  const ImmersiveScreenWithBottomPadding({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.additionalBottomPadding = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ImmersiveScreenWrapper(
      backgroundColor: backgroundColor,
      safeAreaBottom: false,
      child: Column(
        children: [
          Expanded(child: child),
          SizedBox(
            height:
                MediaQuery.of(context).padding.bottom + additionalBottomPadding,
          ),
        ],
      ),
    );
  }
}
