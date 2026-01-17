import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Base font families
  static String get _primaryFont => GoogleFonts.inter().fontFamily!;
  static String get _monoFont => GoogleFonts.jetBrainsMono().fontFamily!;

  // Headings
  static TextStyle get h1 => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get h4 => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Body text
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // Labels
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      );

  // Money display (monospace)
  static TextStyle get moneyLarge => TextStyle(
        fontFamily: _monoFont,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -1,
      );

  static TextStyle get moneyMedium => TextStyle(
        fontFamily: _monoFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get moneySmall => TextStyle(
        fontFamily: _monoFont,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get moneyTiny => TextStyle(
        fontFamily: _monoFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // Button text
  static TextStyle get button => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Navigation
  static TextStyle get navLabel => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // Input
  static TextStyle get input => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get inputHint => TextStyle(
        fontFamily: _primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );
}
