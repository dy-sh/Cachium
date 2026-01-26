import 'package:flutter/material.dart';

class CategoryBreakdown {
  final String categoryId;
  final String name;
  final IconData icon;
  final Color color;
  final double amount;
  final double percentage;
  final int transactionCount;
  final List<CategoryBreakdown> subcategories;

  const CategoryBreakdown({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    this.subcategories = const [],
  });

  CategoryBreakdown copyWith({
    String? categoryId,
    String? name,
    IconData? icon,
    Color? color,
    double? amount,
    double? percentage,
    int? transactionCount,
    List<CategoryBreakdown>? subcategories,
  }) {
    return CategoryBreakdown(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      transactionCount: transactionCount ?? this.transactionCount,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryBreakdown && other.categoryId == categoryId;
  }

  @override
  int get hashCode => categoryId.hashCode;
}
