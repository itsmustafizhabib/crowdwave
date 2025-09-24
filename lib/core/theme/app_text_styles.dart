import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 📝 Application text styles for CrowdWave
/// Implements Contemporary Professional Minimalism typography
class AppTextStyles {
  AppTextStyles._();

  // Base font family
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  // Display Styles (Large headings)
  static TextStyle get display1 => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle get display2 => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // Headings
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get h4 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get h5 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get h6 => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  // Body Text
  static TextStyle get body1 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get body2 => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  // Subtitle
  static TextStyle get subtitle1 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get subtitle2 => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // Caption & Small Text
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
        height: 1.6,
      );

  // Button Styles
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        letterSpacing: 0.5,
        height: 1.25,
      );

  static TextStyle get buttonSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        letterSpacing: 0.5,
        height: 1.25,
      );

  static TextStyle get buttonLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        letterSpacing: 0.5,
        height: 1.25,
      );

  // Specialized Styles

  // Navigation
  static TextStyle get navItem => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get navItemActive => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.25,
      );

  // Form Elements
  static TextStyle get inputLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get inputHint => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get inputError => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.error,
        height: 1.4,
      );

  // Status & Tags
  static TextStyle get tag => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
        height: 1.3,
      );

  static TextStyle get status => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.3,
      );

  // Price & Money
  static TextStyle get price => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get priceSmall => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get priceLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );

  // Links
  static TextStyle get link => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
        height: 1.4,
      );

  static TextStyle get linkLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
        height: 1.4,
      );

  // Special States
  static TextStyle get disabled => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.disabledText,
        height: 1.5,
      );

  static TextStyle get success => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.success,
        height: 1.4,
      );

  static TextStyle get error => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.error,
        height: 1.4,
      );

  static TextStyle get warning => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.warning,
        height: 1.4,
      );

  // Theme Integration
  static TextTheme get lightTextTheme => TextTheme(
        displayLarge: display1,
        displayMedium: display2,
        headlineLarge: h1,
        headlineMedium: h2,
        headlineSmall: h3,
        titleLarge: h4,
        titleMedium: h5,
        titleSmall: h6,
        bodyLarge: body1,
        bodyMedium: body2,
        labelLarge: button,
        labelMedium: buttonSmall,
        labelSmall: caption,
      );

  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: display1.copyWith(color: AppColors.darkTextPrimary),
        displayMedium: display2.copyWith(color: AppColors.darkTextPrimary),
        headlineLarge: h1.copyWith(color: AppColors.darkTextPrimary),
        headlineMedium: h2.copyWith(color: AppColors.darkTextPrimary),
        headlineSmall: h3.copyWith(color: AppColors.darkTextPrimary),
        titleLarge: h4.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: h5.copyWith(color: AppColors.darkTextPrimary),
        titleSmall: h6.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge: body1.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium: body2.copyWith(color: AppColors.darkTextPrimary),
        labelLarge: button,
        labelMedium: buttonSmall,
        labelSmall: caption.copyWith(color: AppColors.darkTextSecondary),
      );
}
