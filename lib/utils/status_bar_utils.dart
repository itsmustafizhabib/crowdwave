import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for managing status bar appearance consistently across the app
class StatusBarUtils {
  /// Default status bar style for screens with blue headers (Travel, Orders, Chat, Profile)
  static const SystemUiOverlayStyle blueHeaderStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness:
        Brightness.light, // Light icons for blue background
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Status bar style for screens with white/light headers (Home, etc.)
  static const SystemUiOverlayStyle lightHeaderStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark icons for light background
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Status bar style for dark themes
  static const SystemUiOverlayStyle darkStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Apply status bar style for blue header screens
  static void setBlueHeaderStyle() {
    SystemChrome.setSystemUIOverlayStyle(blueHeaderStyle);
  }

  /// Apply status bar style for light header screens
  static void setLightHeaderStyle() {
    SystemChrome.setSystemUIOverlayStyle(lightHeaderStyle);
  }

  /// Apply status bar style for dark screens
  static void setDarkStyle() {
    SystemChrome.setSystemUIOverlayStyle(darkStyle);
  }
}
