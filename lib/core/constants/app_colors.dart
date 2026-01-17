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

  // Account type colors (bright outlines)
  static const Color accountBank = Color(0xFF00D4FF);
  static const Color accountCreditCard = Color(0xFFFF6B6B);
  static const Color accountCash = Color(0xFF7CFF6B);
  static const Color accountSavings = Color(0xFFFFD93D);
  static const Color accountInvestment = Color(0xFFB388FF);
  static const Color accountWallet = Color(0xFFFF8F00);

  // Semantic colors
  static const Color income = Color(0xFF00E676);
  static const Color expense = Color(0xFFFF5252);

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
}
