import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../settings/data/models/app_settings.dart';

class AssetCategory {
  final String id;
  final String name;
  final IconData icon;
  final int colorIndex;
  final int sortOrder;
  final DateTime createdAt;

  const AssetCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Color getColor(ColorIntensity intensity) {
    return AppColors.getAccentColor(colorIndex, intensity);
  }

  AssetCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? colorIndex,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return AssetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssetCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Default asset categories seeded on first use.
class DefaultAssetCategories {
  static List<({String name, IconData icon, int colorIndex})> get defaults => [
    (name: 'Vehicle', icon: LucideIcons.car, colorIndex: 0),
    (name: 'Property', icon: LucideIcons.home, colorIndex: 4),
    (name: 'Electronics', icon: LucideIcons.laptop, colorIndex: 8),
    (name: 'Jewelry', icon: LucideIcons.gem, colorIndex: 12),
    (name: 'Collectible', icon: LucideIcons.trophy, colorIndex: 16),
    (name: 'Other', icon: LucideIcons.box, colorIndex: 20),
  ];
}
