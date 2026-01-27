import 'package:flutter/material.dart';

class AccountComparisonData {
  final String accountId;
  final String name;
  final Color color;
  final double totalIncome;
  final double totalExpense;
  final List<AccountBalancePoint> balanceHistory;

  const AccountComparisonData({
    required this.accountId,
    required this.name,
    required this.color,
    required this.totalIncome,
    required this.totalExpense,
    required this.balanceHistory,
  });

  double get net => totalIncome - totalExpense;
}

class AccountBalancePoint {
  final DateTime date;
  final String label;
  final double balance;

  const AccountBalancePoint({
    required this.date,
    required this.label,
    required this.balance,
  });
}
