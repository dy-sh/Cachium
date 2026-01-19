import 'package:flutter/material.dart';
import '../../features/settings/data/models/app_settings.dart';

class AppColors {
  AppColors._();

  // Background colors
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceLight = Color(0xFF121212);

  // Border colors
  static const Color border = Color(0xFF1F1F1F);
  static const Color borderSelected = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textTertiary = Color(0xFF5A5A5A);

  // Accent colors
  static const Color accentPrimary = Color(0xFFFFFFFF);
  static const Color selectionGlow = Color(0x33FFFFFF); // 20% opacity white

  // Accent color options - Bright (vivid, fully saturated)
  static const List<Color> accentOptionsBright = [
    Color(0xFFFFFFFF), // White (default)
    // Blues
    Color(0xFF00E5FF), // Electric Cyan
    Color(0xFF40C4FF), // Vivid Sky Blue
    Color(0xFF536DFE), // Vivid Cornflower
    Color(0xFF2979FF), // Vivid Royal Blue
    Color(0xFF00B0FF), // Vivid Dodger Blue
    Color(0xFF18FFFF), // Bright Cyan
    // Other colors
    Color(0xFF00E676), // Vivid Green
    Color(0xFF69F0AE), // Bright Light Green
    Color(0xFFFF1744), // Vivid Red
    Color(0xFFFF5252), // Bright Salmon
    Color(0xFFFFEA00), // Electric Yellow
    Color(0xFFFFFF00), // Bright Gold
    Color(0xFFD500F9), // Electric Purple
    Color(0xFFE040FB), // Bright Purple
    Color(0xFFFF6D00), // Vivid Orange
    Color(0xFFFF9100), // Bright Orange
    Color(0xFFFF4081), // Vivid Pink
    Color(0xFFFF80AB), // Bright Pink
  ];

  // Accent color options - Dim (softer, less saturated)
  static const List<Color> accentOptionsDim = [
    Color(0xFFFFFFFF), // White (default)
    // Blues
    Color(0xFF00D4FF), // Cyan
    Color(0xFF4DA6FF), // Sky Blue
    Color(0xFF6B8CFF), // Cornflower Blue
    Color(0xFF3366FF), // Royal Blue
    Color(0xFF1E90FF), // Dodger Blue
    Color(0xFF00BFFF), // Deep Sky Blue
    // Other colors
    Color(0xFF00FF88), // Green
    Color(0xFF7CFF7C), // Light Green
    Color(0xFFFF6B6B), // Red
    Color(0xFFFF8585), // Salmon
    Color(0xFFFFDD4D), // Yellow
    Color(0xFFFFE066), // Light Gold
    Color(0xFFC098FF), // Purple
    Color(0xFFB388FF), // Light Purple
    Color(0xFFFF9D1A), // Orange
    Color(0xFFFFAD33), // Light Orange
    Color(0xFFFF69B4), // Pink
    Color(0xFFFF85C8), // Light Pink
  ];

  // Legacy accessor (use bright by default)
  static const List<Color> accentOptions = accentOptionsBright;

  // Get accent options based on intensity
  static List<Color> getAccentOptions(ColorIntensity intensity) {
    return intensity == ColorIntensity.bright ? accentOptionsBright : accentOptionsDim;
  }

  // Get specific accent color by index with intensity
  static Color getAccentColor(int index, ColorIntensity intensity) {
    final options = getAccentOptions(intensity);
    return options[index.clamp(0, options.length - 1)];
  }

  // Account type colors - Bright (vivid, fully saturated)
  static const Color accountBankBright = Color(0xFF00E5FF);    // Electric cyan
  static const Color accountCreditCardBright = Color(0xFFFF1744);  // Vivid red
  static const Color accountCashBright = Color(0xFF00E676);    // Vivid green
  static const Color accountSavingsBright = Color(0xFFFFEA00);  // Electric yellow
  static const Color accountInvestmentBright = Color(0xFFD500F9);  // Electric purple
  static const Color accountWalletBright = Color(0xFFFF6D00);  // Vivid orange

  // Account type colors - Dim (current default, balanced visibility)
  static const Color accountBankDim = Color(0xFF1ADEFF);
  static const Color accountCreditCardDim = Color(0xFFFF7575);
  static const Color accountCashDim = Color(0xFF8AFF7A);
  static const Color accountSavingsDim = Color(0xFFFFDD4D);
  static const Color accountInvestmentDim = Color(0xFFC098FF);
  static const Color accountWalletDim = Color(0xFFFF9D1A);

  // Legacy accessors (use dim by default)
  static const Color accountBank = accountBankDim;
  static const Color accountCreditCard = accountCreditCardDim;
  static const Color accountCash = accountCashDim;
  static const Color accountSavings = accountSavingsDim;
  static const Color accountInvestment = accountInvestmentDim;
  static const Color accountWallet = accountWalletDim;

  // Semantic colors - Bright (vivid, fully saturated)
  static const Color incomeBright = Color(0xFF00E676);  // Vivid green
  static const Color expenseBright = Color(0xFFFF1744);  // Vivid red

  // Semantic colors - Dim (current default, balanced visibility)
  static const Color incomeDim = Color(0xFF00FF88);
  static const Color expenseDim = Color(0xFFFF6B6B);

  // Legacy semantic colors (dim by default)
  static const Color income = incomeDim;
  static const Color expense = expenseDim;

  // Navigation colors
  static const Color navActive = Color(0xFFFFFFFF);
  static const Color navInactive = Color(0xFF5A5A5A);

  // Category colors (for custom categories)
  static const List<Color> categoryColors = [
    Color(0xFFFF7043), // Deep Orange
    Color(0xFF42A5F5), // Blue
    Color(0xFFEC407A), // Pink
    Color(0xFFAB47BC), // Purple
    Color(0xFFFFCA28), // Amber
    Color(0xFFEF5350), // Red
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF26A69A), // Teal
    Color(0xFF00E676), // Green
    Color(0xFF00BCD4), // Cyan
    Color(0xFF7C4DFF), // Deep Purple
    Color(0xFFFF4081), // Pink Accent
  ];

  // Get account color by type with intensity support
  static Color getAccountColor(String type, [ColorIntensity intensity = ColorIntensity.bright]) {
    final isBright = intensity == ColorIntensity.bright;
    switch (type) {
      case 'bank':
        return isBright ? accountBankBright : accountBankDim;
      case 'creditCard':
        return isBright ? accountCreditCardBright : accountCreditCardDim;
      case 'cash':
        return isBright ? accountCashBright : accountCashDim;
      case 'savings':
        return isBright ? accountSavingsBright : accountSavingsDim;
      case 'investment':
        return isBright ? accountInvestmentBright : accountInvestmentDim;
      case 'wallet':
        return isBright ? accountWalletBright : accountWalletDim;
      default:
        return isBright ? accountBankBright : accountBankDim;
    }
  }

  // Get transaction color by type with intensity support
  static Color getTransactionColor(String type, [ColorIntensity intensity = ColorIntensity.bright]) {
    final isBright = intensity == ColorIntensity.bright;
    switch (type) {
      case 'income':
        return isBright ? incomeBright : incomeDim;
      case 'expense':
        return isBright ? expenseBright : expenseDim;
      default:
        return textPrimary;
    }
  }

  // Utility methods for color variations
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
