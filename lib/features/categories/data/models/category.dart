import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../settings/data/models/app_settings.dart';

enum CategoryType {
  income,
  expense,
}

class Category {
  final String id;
  final String name;
  final IconData icon;
  final int colorIndex;
  final CategoryType type;
  final bool isCustom;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    required this.type,
    this.isCustom = false,
  });

  /// Returns the color for this category based on the current palette.
  Color getColor(ColorIntensity palette) {
    final colors = AppColors.getCategoryColors(palette);
    return colors[colorIndex.clamp(0, colors.length - 1)];
  }

  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? colorIndex,
    CategoryType? type,
    bool? isCustom,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
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
  // Color indices map to: [cyan, skyBlue, green, lightGreen, red, salmon, yellow, purple, lightPurple, orange, pink, lightPink]
  static const List<Category> income = [
    Category(
      id: 'salary',
      name: 'Salary',
      icon: LucideIcons.briefcase,
      colorIndex: 2, // green
      type: CategoryType.income,
    ),
    Category(
      id: 'freelance',
      name: 'Freelance',
      icon: LucideIcons.laptop,
      colorIndex: 0, // cyan
      type: CategoryType.income,
    ),
    Category(
      id: 'investment_income',
      name: 'Investment',
      icon: LucideIcons.trendingUp,
      colorIndex: 7, // purple
      type: CategoryType.income,
    ),
    Category(
      id: 'gift_income',
      name: 'Gift',
      icon: LucideIcons.gift,
      colorIndex: 10, // pink
      type: CategoryType.income,
    ),
    Category(
      id: 'other_income',
      name: 'Other',
      icon: LucideIcons.plus,
      colorIndex: 1, // skyBlue
      type: CategoryType.income,
    ),
  ];

  static const List<Category> expense = [
    Category(
      id: 'food',
      name: 'Food',
      icon: LucideIcons.utensils,
      colorIndex: 9, // orange
      type: CategoryType.expense,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: LucideIcons.car,
      colorIndex: 1, // skyBlue
      type: CategoryType.expense,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: LucideIcons.shoppingBag,
      colorIndex: 10, // pink
      type: CategoryType.expense,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: LucideIcons.gamepad2,
      colorIndex: 7, // purple
      type: CategoryType.expense,
    ),
    Category(
      id: 'bills',
      name: 'Bills',
      icon: LucideIcons.receipt,
      colorIndex: 6, // yellow
      type: CategoryType.expense,
    ),
    Category(
      id: 'health',
      name: 'Health',
      icon: LucideIcons.heartPulse,
      colorIndex: 4, // red
      type: CategoryType.expense,
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: LucideIcons.graduationCap,
      colorIndex: 8, // lightPurple
      type: CategoryType.expense,
    ),
    Category(
      id: 'travel',
      name: 'Travel',
      icon: LucideIcons.plane,
      colorIndex: 0, // cyan
      type: CategoryType.expense,
    ),
    Category(
      id: 'other_expense',
      name: 'Other',
      icon: LucideIcons.moreHorizontal,
      colorIndex: 5, // salmon
      type: CategoryType.expense,
    ),
  ];

  static List<Category> get all => [...income, ...expense];
}
