import 'package:flutter/material.dart';

class BudgetForecast {
  final String categoryId;
  final String categoryName;
  final Color categoryColor;
  final double currentSpending;
  final double projectedSpending;
  final double budgetAmount;
  final double overage;
  final double dailyRate;
  final int daysRemaining;

  const BudgetForecast({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.currentSpending,
    required this.projectedSpending,
    required this.budgetAmount,
    required this.overage,
    required this.dailyRate,
    required this.daysRemaining,
  });

  double get overagePercent =>
      budgetAmount > 0 ? (overage / budgetAmount * 100) : 0;

  bool get isOverBudget => overage > 0;

  BudgetForecast copyWith({
    String? categoryId,
    String? categoryName,
    Color? categoryColor,
    double? currentSpending,
    double? projectedSpending,
    double? budgetAmount,
    double? overage,
    double? dailyRate,
    int? daysRemaining,
  }) {
    return BudgetForecast(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      currentSpending: currentSpending ?? this.currentSpending,
      projectedSpending: projectedSpending ?? this.projectedSpending,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      overage: overage ?? this.overage,
      dailyRate: dailyRate ?? this.dailyRate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetForecast && other.categoryId == categoryId;
  }

  @override
  int get hashCode => categoryId.hashCode;
}
