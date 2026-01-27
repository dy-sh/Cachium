import 'package:flutter/material.dart';
import 'budget.dart';

class BudgetProgress {
  final Budget budget;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final double spent;
  final double remaining;
  final double percentage;
  final bool isOverBudget;

  const BudgetProgress({
    required this.budget,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.isOverBudget,
  });
}
