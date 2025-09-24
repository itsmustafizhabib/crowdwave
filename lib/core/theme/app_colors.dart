import 'package:flutter/material.dart';

/// 🎨 Application color constants for CrowdWave
/// Implements Contemporary Professional Minimalism with Trust-Forward Professional color strategy
class AppColors {
  AppColors._();

  // Primary Colors from AppTheme
  static const Color primary = Color(0xFF001BB7); // Dark Navy - Primary dark
  static const Color primaryVariant =
      Color(0xFF0046FF); // Electric Blue - Primary
  static const Color secondary =
      Color(0xFF0046FF); // Electric Blue for interactive elements
  static const Color accent = Color(0xFFFF8040); // Orange Accent - Accent/CTA

  // Background & Surface
  static const Color background = Color(0xFFE9E9E9); // Light Grey - Background
  static const Color surface = Color(0xFFFFFFFF); // Pure white - Surface

  // Status Colors
  static const Color success = Color(0xFF28A745); // Standard green
  static const Color error = Color(0xFFB00020); // Error red
  static const Color warning = Color(0xFFFFC107); // Amber for caution
  static const Color info = Color(0xFF17A2B8); // Info blue

  // Text Colors
  static const Color textPrimary = Color(0xFF212529); // Near-black
  static const Color textSecondary =
      Color(0xFF6C757D); // Medium gray for secondary text
  static const Color textTertiary =
      Color(0xFF9CA3AF); // Light gray for tertiary text
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary
  static const Color textOnSecondary =
      Color(0xFFFFFFFF); // White text on secondary

  // Border & Divider
  static const Color border = Color(0xFFE5E7EB); // Light border
  static const Color divider = Color(0xFFE5E7EB); // Divider color

  // Interactive States
  static const Color hover = Color(0xFFF8F9FA); // Hover state
  static const Color focus = Color(0xFFE3F2FD); // Focus state
  static const Color disabled = Color(0xFFE9ECEF); // Disabled state
  static const Color disabledText = Color(0xFF9CA3AF); // Disabled text

  // Transparent Orange for Status Bar (based on accent color)
  static const Color statusBarBackground =
      Color(0x80FF8040); // 50% transparent orange

  // Solid Blue Status Bar Background (matching home screen header)
  static const Color solidBlueStatusBar =
      Color(0xFF0046FF); // Electric Blue - matches headers

  /// Status bar configuration method
  /// Returns the solid blue color for universal status bar styling
  static Color get statusBarBlue => solidBlueStatusBar;

  // Shadow & Overlay
  static const Color shadow = Color(0x1A000000); // Shadow color
  static const Color overlay = Color(0x80000000); // Overlay color

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF001BB7),
    Color(0xFF0046FF),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFFF8040),
    Color(0xFFFF6B35),
  ];

  // Dark Mode Colors (for future implementation)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get semantic colors for booking status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return warning;
      case 'confirmed':
        return success;
      case 'cancelled':
        return error;
      case 'completed':
        return success;
      case 'in_progress':
        return info;
      default:
        return textSecondary;
    }
  }

  /// Get priority colors
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return error;
      case 'medium':
        return warning;
      case 'low':
        return success;
      default:
        return textSecondary;
    }
  }

  /// Color scheme for theme generation
  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      );

  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primaryVariant,
        secondary: accent,
        surface: darkSurface,
        background: darkBackground,
        error: error,
      );
}
