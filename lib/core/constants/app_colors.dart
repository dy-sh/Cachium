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

  // Accent color options for settings
  static const List<Color> accentOptions = [
    Color(0xFFFFFFFF), // White (default)
    Color(0xFF00D4FF), // Cyan
    Color(0xFF00FF88), // Green
    Color(0xFFFF6B6B), // Red
    Color(0xFFFFDD4D), // Yellow
    Color(0xFFC098FF), // Purple
    Color(0xFFFF9D1A), // Orange
    Color(0xFFFF69B4), // Pink
  ];

  // Account type colors - Bright (enhanced +10% brightness)
  static const Color accountBankBright = Color(0xFF1ADEFF);
  static const Color accountCreditCardBright = Color(0xFFFF7575);
  static const Color accountCashBright = Color(0xFF8AFF7A);
  static const Color accountSavingsBright = Color(0xFFFFDD4D);
  static const Color accountInvestmentBright = Color(0xFFC098FF);
  static const Color accountWalletBright = Color(0xFFFF9D1A);

  // Account type colors - Dim (muted versions)
  static const Color accountBankDim = Color(0xFF0D6F80);
  static const Color accountCreditCardDim = Color(0xFF803B3B);
  static const Color accountCashDim = Color(0xFF457F3D);
  static const Color accountSavingsDim = Color(0xFF806F27);
  static const Color accountInvestmentDim = Color(0xFF604C80);
  static const Color accountWalletDim = Color(0xFF804F0D);

  // Legacy accessors (use bright by default)
  static const Color accountBank = accountBankBright;
  static const Color accountCreditCard = accountCreditCardBright;
  static const Color accountCash = accountCashBright;
  static const Color accountSavings = accountSavingsBright;
  static const Color accountInvestment = accountInvestmentBright;
  static const Color accountWallet = accountWalletBright;

  // Semantic colors - Bright
  static const Color incomeBright = Color(0xFF00FF88);
  static const Color expenseBright = Color(0xFFFF6B6B);

  // Semantic colors - Dim
  static const Color incomeDim = Color(0xFF00804A);
  static const Color expenseDim = Color(0xFF803636);

  // Legacy semantic colors (bright by default)
  static const Color income = incomeBright;
  static const Color expense = expenseBright;

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
