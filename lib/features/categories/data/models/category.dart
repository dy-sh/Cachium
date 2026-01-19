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
  final String? parentId; // null = root level
  final int sortOrder; // ordering within same parent

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    required this.type,
    this.isCustom = false,
    this.parentId,
    this.sortOrder = 0,
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
    String? parentId,
    bool clearParentId = false,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      type: type ?? this.type,
      isCustom: isCustom ?? this.isCustom,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      sortOrder: sortOrder ?? this.sortOrder,
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
      sortOrder: 0,
    ),
    Category(
      id: 'freelance',
      name: 'Freelance',
      icon: LucideIcons.laptop,
      colorIndex: 0, // cyan
      type: CategoryType.income,
      sortOrder: 1,
    ),
    Category(
      id: 'investment_income',
      name: 'Investment',
      icon: LucideIcons.trendingUp,
      colorIndex: 7, // purple
      type: CategoryType.income,
      sortOrder: 2,
    ),
    Category(
      id: 'gift_income',
      name: 'Gift',
      icon: LucideIcons.gift,
      colorIndex: 10, // pink
      type: CategoryType.income,
      sortOrder: 3,
    ),
    Category(
      id: 'other_income',
      name: 'Other',
      icon: LucideIcons.plus,
      colorIndex: 1, // skyBlue
      type: CategoryType.income,
      sortOrder: 4,
    ),
  ];

  static const List<Category> expense = [
    // Food (parent)
    Category(
      id: 'food',
      name: 'Food',
      icon: LucideIcons.utensils,
      colorIndex: 9, // orange
      type: CategoryType.expense,
      sortOrder: 0,
    ),
    // Food subcategories
    Category(
      id: 'food_groceries',
      name: 'Groceries',
      icon: LucideIcons.shoppingCart,
      colorIndex: 9, // orange
      type: CategoryType.expense,
      parentId: 'food',
      sortOrder: 0,
    ),
    Category(
      id: 'food_restaurants',
      name: 'Restaurants',
      icon: LucideIcons.utensilsCrossed,
      colorIndex: 9, // orange
      type: CategoryType.expense,
      parentId: 'food',
      sortOrder: 1,
    ),
    Category(
      id: 'food_delivery',
      name: 'Delivery',
      icon: LucideIcons.bike,
      colorIndex: 9, // orange
      type: CategoryType.expense,
      parentId: 'food',
      sortOrder: 2,
    ),
    // Transport (parent)
    Category(
      id: 'transport',
      name: 'Transport',
      icon: LucideIcons.car,
      colorIndex: 1, // skyBlue
      type: CategoryType.expense,
      sortOrder: 1,
    ),
    // Transport subcategories
    Category(
      id: 'transport_fuel',
      name: 'Fuel',
      icon: LucideIcons.fuel,
      colorIndex: 1, // skyBlue
      type: CategoryType.expense,
      parentId: 'transport',
      sortOrder: 0,
    ),
    Category(
      id: 'transport_public',
      name: 'Public Transit',
      icon: LucideIcons.bus,
      colorIndex: 1, // skyBlue
      type: CategoryType.expense,
      parentId: 'transport',
      sortOrder: 1,
    ),
    Category(
      id: 'transport_parking',
      name: 'Parking',
      icon: LucideIcons.parkingCircle,
      colorIndex: 1, // skyBlue
      type: CategoryType.expense,
      parentId: 'transport',
      sortOrder: 2,
    ),
    // Shopping (parent)
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: LucideIcons.shoppingBag,
      colorIndex: 10, // pink
      type: CategoryType.expense,
      sortOrder: 2,
    ),
    // Shopping subcategories
    Category(
      id: 'shopping_clothes',
      name: 'Clothes',
      icon: LucideIcons.shirt,
      colorIndex: 10, // pink
      type: CategoryType.expense,
      parentId: 'shopping',
      sortOrder: 0,
    ),
    Category(
      id: 'shopping_electronics',
      name: 'Electronics',
      icon: LucideIcons.smartphone,
      colorIndex: 10, // pink
      type: CategoryType.expense,
      parentId: 'shopping',
      sortOrder: 1,
    ),
    Category(
      id: 'shopping_home',
      name: 'Home',
      icon: LucideIcons.home,
      colorIndex: 10, // pink
      type: CategoryType.expense,
      parentId: 'shopping',
      sortOrder: 2,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: LucideIcons.gamepad2,
      colorIndex: 7, // purple
      type: CategoryType.expense,
      sortOrder: 3,
    ),
    // Bills (parent)
    Category(
      id: 'bills',
      name: 'Bills',
      icon: LucideIcons.receipt,
      colorIndex: 6, // yellow
      type: CategoryType.expense,
      sortOrder: 4,
    ),
    // Bills subcategories
    Category(
      id: 'bills_utilities',
      name: 'Utilities',
      icon: LucideIcons.zap,
      colorIndex: 6, // yellow
      type: CategoryType.expense,
      parentId: 'bills',
      sortOrder: 0,
    ),
    Category(
      id: 'bills_rent',
      name: 'Rent',
      icon: LucideIcons.building,
      colorIndex: 6, // yellow
      type: CategoryType.expense,
      parentId: 'bills',
      sortOrder: 1,
    ),
    Category(
      id: 'bills_insurance',
      name: 'Insurance',
      icon: LucideIcons.shield,
      colorIndex: 6, // yellow
      type: CategoryType.expense,
      parentId: 'bills',
      sortOrder: 2,
    ),
    Category(
      id: 'health',
      name: 'Health',
      icon: LucideIcons.heartPulse,
      colorIndex: 4, // red
      type: CategoryType.expense,
      sortOrder: 5,
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: LucideIcons.graduationCap,
      colorIndex: 8, // lightPurple
      type: CategoryType.expense,
      sortOrder: 6,
    ),
    Category(
      id: 'travel',
      name: 'Travel',
      icon: LucideIcons.plane,
      colorIndex: 0, // cyan
      type: CategoryType.expense,
      sortOrder: 7,
    ),
    Category(
      id: 'other_expense',
      name: 'Other',
      icon: LucideIcons.moreHorizontal,
      colorIndex: 5, // salmon
      type: CategoryType.expense,
      sortOrder: 8,
    ),
  ];

  static List<Category> get all => [...income, ...expense];
}
