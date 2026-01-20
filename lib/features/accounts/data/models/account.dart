import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../settings/data/models/app_settings.dart';

enum AccountType {
  bank,
  creditCard,
  cash,
  savings,
  investment,
  wallet,
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.bank:
        return 'Bank';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.cash:
        return 'Cash';
      case AccountType.savings:
        return 'Savings';
      case AccountType.investment:
        return 'Investment';
      case AccountType.wallet:
        return 'Wallet';
    }
  }

  Color get color {
    switch (this) {
      case AccountType.bank:
        return AppColors.accountBank;
      case AccountType.creditCard:
        return AppColors.accountCreditCard;
      case AccountType.cash:
        return AppColors.accountCash;
      case AccountType.savings:
        return AppColors.accountSavings;
      case AccountType.investment:
        return AppColors.accountInvestment;
      case AccountType.wallet:
        return AppColors.accountWallet;
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.cash:
        return Icons.payments;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.wallet:
        return Icons.account_balance_wallet;
    }
  }
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final double initialBalance;
  final Color? customColor;
  final IconData? customIcon;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.initialBalance,
    this.customColor,
    this.customIcon,
    required this.createdAt,
  });

  Color get color => customColor ?? type.color;
  IconData get icon => customIcon ?? type.icon;

  /// Returns the account color with the specified intensity.
  /// If the account has a custom color, it returns that color unchanged.
  Color getColorWithIntensity(ColorIntensity intensity) {
    return customColor ?? AppColors.getAccountColor(type.name, intensity);
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    double? initialBalance,
    Color? customColor,
    IconData? customIcon,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      customColor: customColor ?? this.customColor,
      customIcon: customIcon ?? this.customIcon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
