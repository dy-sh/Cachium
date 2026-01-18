import 'package:flutter/material.dart';

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

  // Account type colors (bright outlines - enhanced +10% brightness)
  static const Color accountBank = Color(0xFF1ADEFF);
  static const Color accountCreditCard = Color(0xFFFF7575);
  static const Color accountCash = Color(0xFF8AFF7A);
  static const Color accountSavings = Color(0xFFFFDD4D);
  static const Color accountInvestment = Color(0xFFC098FF);
  static const Color accountWallet = Color(0xFFFF9D1A);

  // Semantic colors (brightened)
  static const Color income = Color(0xFF00FF88);
  static const Color expense = Color(0xFFFF6B6B);

  // Navigation colors
  static const Color navActive = Color(0xFFFFFFFF);
  static const Color navInactive = Color(0xFF5A5A5A);

  // Get account color by type
  static Color getAccountColor(String type) {
    switch (type) {
      case 'bank':
        return accountBank;
      case 'creditCard':
        return accountCreditCard;
      case 'cash':
        return accountCash;
      case 'savings':
        return accountSavings;
      case 'investment':
        return accountInvestment;
      case 'wallet':
        return accountWallet;
      default:
        return accountBank;
    }
  }

  // Get transaction color by type
  static Color getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return income;
      case 'expense':
        return expense;
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
