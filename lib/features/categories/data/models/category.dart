import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum CategoryType {
  income,
  expense,
}

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final CategoryType type;
  final bool isCustom;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isCustom = false,
  });

  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    CategoryType? type,
    bool? isCustom,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class DefaultCategories {
  static const List<Category> income = [
    Category(
      id: 'salary',
      name: 'Salary',
      icon: LucideIcons.briefcase,
      color: Color(0xFF00E676),
      type: CategoryType.income,
    ),
    Category(
      id: 'freelance',
      name: 'Freelance',
      icon: LucideIcons.laptop,
      color: Color(0xFF00BCD4),
      type: CategoryType.income,
    ),
    Category(
      id: 'investment_income',
      name: 'Investment',
      icon: LucideIcons.trendingUp,
      color: Color(0xFF7C4DFF),
      type: CategoryType.income,
    ),
    Category(
      id: 'gift_income',
      name: 'Gift',
      icon: LucideIcons.gift,
      color: Color(0xFFFF4081),
      type: CategoryType.income,
    ),
    Category(
      id: 'other_income',
      name: 'Other',
      icon: LucideIcons.plus,
      color: Color(0xFF8A8A8A),
      type: CategoryType.income,
    ),
  ];

  static const List<Category> expense = [
    Category(
      id: 'food',
      name: 'Food',
      icon: LucideIcons.utensils,
      color: Color(0xFFFF7043),
      type: CategoryType.expense,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: LucideIcons.car,
      color: Color(0xFF42A5F5),
      type: CategoryType.expense,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: LucideIcons.shoppingBag,
      color: Color(0xFFEC407A),
      type: CategoryType.expense,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: LucideIcons.gamepad2,
      color: Color(0xFFAB47BC),
      type: CategoryType.expense,
    ),
    Category(
      id: 'bills',
      name: 'Bills',
      icon: LucideIcons.receipt,
      color: Color(0xFFFFCA28),
      type: CategoryType.expense,
    ),
    Category(
      id: 'health',
      name: 'Health',
      icon: LucideIcons.heartPulse,
      color: Color(0xFFEF5350),
      type: CategoryType.expense,
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: LucideIcons.graduationCap,
      color: Color(0xFF5C6BC0),
      type: CategoryType.expense,
    ),
    Category(
      id: 'travel',
      name: 'Travel',
      icon: LucideIcons.plane,
      color: Color(0xFF26A69A),
      type: CategoryType.expense,
    ),
    Category(
      id: 'other_expense',
      name: 'Other',
      icon: LucideIcons.moreHorizontal,
      color: Color(0xFF8A8A8A),
      type: CategoryType.expense,
    ),
  ];

  static List<Category> get all => [...income, ...expense];
}
