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
    final colors = AppColors.getAccentOptions(palette);
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
  // Color indices for 24-color accent palette (0=white, 1-23=hues at 15° spacing)
  // 1=red, 3=orange, 5=yellow, 7=lime, 9=green, 11=jade, 13=cyan,
  // 15=azure, 17=blue, 19=violet, 20=purple, 21=magenta, 22=fuchsia, 23=rose
  static const List<Category> income = [
    Category(
      id: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
      name: 'Salary',
      icon: LucideIcons.briefcase,
      colorIndex: 9, // green - money earned
      type: CategoryType.income,
      sortOrder: 0,
    ),
    Category(
      id: 'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
      name: 'Freelance',
      icon: LucideIcons.laptop,
      colorIndex: 13, // cyan - tech/digital
      type: CategoryType.income,
      sortOrder: 1,
    ),
    Category(
      id: 'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f',
      name: 'Investment',
      icon: LucideIcons.trendingUp,
      colorIndex: 17, // blue - financial
      type: CategoryType.income,
      sortOrder: 2,
    ),
    Category(
      id: 'd4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f8a',
      name: 'Gift',
      icon: LucideIcons.gift,
      colorIndex: 21, // magenta - special
      type: CategoryType.income,
      sortOrder: 3,
    ),
    Category(
      id: 'e5f6a7b8-c9d0-4e1f-2a3b-4c5d6e7f8a9b',
      name: 'Other',
      icon: LucideIcons.plus,
      colorIndex: 14, // sky - neutral
      type: CategoryType.income,
      sortOrder: 4,
    ),
  ];

  static const List<Category> expense = [
    // Food (parent)
    Category(
      id: 'f6a7b8c9-d0e1-4f2a-3b4c-5d6e7f8a9b0c',
      name: 'Food',
      icon: LucideIcons.utensils,
      colorIndex: 3, // orange - warm/appetite
      type: CategoryType.expense,
      sortOrder: 0,
    ),
    // Food subcategories
    Category(
      id: 'f7a8b9c0-d1e2-4f3a-4b5c-6d7e8f9a0b1c',
      name: 'Groceries',
      icon: LucideIcons.shoppingCart,
      colorIndex: 3, // orange
      type: CategoryType.expense,
      parentId: 'f6a7b8c9-d0e1-4f2a-3b4c-5d6e7f8a9b0c',
      sortOrder: 0,
    ),
    Category(
      id: 'f8a9b0c1-d2e3-4f4a-5b6c-7d8e9f0a1b2c',
      name: 'Restaurants',
      icon: LucideIcons.utensilsCrossed,
      colorIndex: 3, // orange
      type: CategoryType.expense,
      parentId: 'f6a7b8c9-d0e1-4f2a-3b4c-5d6e7f8a9b0c',
      sortOrder: 1,
    ),
    Category(
      id: 'f9a0b1c2-d3e4-4f5a-6b7c-8d9e0f1a2b3c',
      name: 'Delivery',
      icon: LucideIcons.bike,
      colorIndex: 3, // orange
      type: CategoryType.expense,
      parentId: 'f6a7b8c9-d0e1-4f2a-3b4c-5d6e7f8a9b0c',
      sortOrder: 2,
    ),
    // Transport (parent)
    Category(
      id: 'a7b8c9d0-e1f2-4a3b-4c5d-6e7f8a9b0c1d',
      name: 'Transport',
      icon: LucideIcons.car,
      colorIndex: 17, // blue - movement
      type: CategoryType.expense,
      sortOrder: 1,
    ),
    // Transport subcategories
    Category(
      id: 'a8b9c0d1-e2f3-4a4b-5c6d-7e8f9a0b1c2d',
      name: 'Fuel',
      icon: LucideIcons.fuel,
      colorIndex: 17, // blue
      type: CategoryType.expense,
      parentId: 'a7b8c9d0-e1f2-4a3b-4c5d-6e7f8a9b0c1d',
      sortOrder: 0,
    ),
    Category(
      id: 'a9b0c1d2-e3f4-4a5b-6c7d-8e9f0a1b2c3d',
      name: 'Public Transit',
      icon: LucideIcons.bus,
      colorIndex: 17, // blue
      type: CategoryType.expense,
      parentId: 'a7b8c9d0-e1f2-4a3b-4c5d-6e7f8a9b0c1d',
      sortOrder: 1,
    ),
    Category(
      id: 'a0b1c2d3-e4f5-4a6b-7c8d-9e0f1a2b3c4d',
      name: 'Parking',
      icon: LucideIcons.parkingCircle,
      colorIndex: 17, // blue
      type: CategoryType.expense,
      parentId: 'a7b8c9d0-e1f2-4a3b-4c5d-6e7f8a9b0c1d',
      sortOrder: 2,
    ),
    // Shopping (parent)
    Category(
      id: 'b8c9d0e1-f2a3-4b4c-5d6e-7f8a9b0c1d2e',
      name: 'Shopping',
      icon: LucideIcons.shoppingBag,
      colorIndex: 22, // fuchsia - retail
      type: CategoryType.expense,
      sortOrder: 2,
    ),
    // Shopping subcategories
    Category(
      id: 'b9c0d1e2-f3a4-4b5c-6d7e-8f9a0b1c2d3e',
      name: 'Clothes',
      icon: LucideIcons.shirt,
      colorIndex: 22, // fuchsia
      type: CategoryType.expense,
      parentId: 'b8c9d0e1-f2a3-4b4c-5d6e-7f8a9b0c1d2e',
      sortOrder: 0,
    ),
    Category(
      id: 'b0c1d2e3-f4a5-4b6c-7d8e-9f0a1b2c3d4e',
      name: 'Electronics',
      icon: LucideIcons.smartphone,
      colorIndex: 22, // fuchsia
      type: CategoryType.expense,
      parentId: 'b8c9d0e1-f2a3-4b4c-5d6e-7f8a9b0c1d2e',
      sortOrder: 1,
    ),
    Category(
      id: 'b1c2d3e4-f5a6-4b7c-8d9e-0f1a2b3c4d5e',
      name: 'Home',
      icon: LucideIcons.home,
      colorIndex: 22, // fuchsia
      type: CategoryType.expense,
      parentId: 'b8c9d0e1-f2a3-4b4c-5d6e-7f8a9b0c1d2e',
      sortOrder: 2,
    ),
    Category(
      id: 'd0e1f2a3-b4c5-4d6e-7f8a-9b0c1d2e3f4a',
      name: 'Entertainment',
      icon: LucideIcons.gamepad2,
      colorIndex: 19, // violet - fun
      type: CategoryType.expense,
      sortOrder: 3,
    ),
    // Bills (parent)
    Category(
      id: 'c9d0e1f2-a3b4-4c5d-6e7f-8a9b0c1d2e3f',
      name: 'Bills',
      icon: LucideIcons.receipt,
      colorIndex: 5, // yellow - attention
      type: CategoryType.expense,
      sortOrder: 4,
    ),
    // Bills subcategories
    Category(
      id: 'c0d1e2f3-a4b5-4c6d-7e8f-9a0b1c2d3e4f',
      name: 'Utilities',
      icon: LucideIcons.zap,
      colorIndex: 5, // yellow
      type: CategoryType.expense,
      parentId: 'c9d0e1f2-a3b4-4c5d-6e7f-8a9b0c1d2e3f',
      sortOrder: 0,
    ),
    Category(
      id: 'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f',
      name: 'Rent',
      icon: LucideIcons.building,
      colorIndex: 5, // yellow
      type: CategoryType.expense,
      parentId: 'c9d0e1f2-a3b4-4c5d-6e7f-8a9b0c1d2e3f',
      sortOrder: 1,
    ),
    Category(
      id: 'c2d3e4f5-a6b7-4c8d-9e0f-1a2b3c4d5e6f',
      name: 'Insurance',
      icon: LucideIcons.shield,
      colorIndex: 5, // yellow
      type: CategoryType.expense,
      parentId: 'c9d0e1f2-a3b4-4c5d-6e7f-8a9b0c1d2e3f',
      sortOrder: 2,
    ),
    Category(
      id: 'd1e2f3a4-b5c6-4d7e-8f9a-0b1c2d3e4f5a',
      name: 'Health',
      icon: LucideIcons.heartPulse,
      colorIndex: 1, // red - medical
      type: CategoryType.expense,
      sortOrder: 5,
    ),
    Category(
      id: 'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',
      name: 'Education',
      icon: LucideIcons.graduationCap,
      colorIndex: 18, // indigo - knowledge
      type: CategoryType.expense,
      sortOrder: 6,
    ),
    Category(
      id: 'd3e4f5a6-b7c8-4d9e-0f1a-2b3c4d5e6f7a',
      name: 'Travel',
      icon: LucideIcons.plane,
      colorIndex: 13, // cyan - sky/water
      type: CategoryType.expense,
      sortOrder: 7,
    ),
    Category(
      id: 'd4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f8a',
      name: 'Other',
      icon: LucideIcons.moreHorizontal,
      colorIndex: 14, // sky - neutral
      type: CategoryType.expense,
      sortOrder: 8,
    ),
  ];

  static List<Category> get all => [...income, ...expense];
}
