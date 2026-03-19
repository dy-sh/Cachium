import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../settings/data/models/app_settings.dart';

class Tag {
  final String id;
  final String name;
  final int colorIndex;
  final IconData icon;
  final int sortOrder;

  const Tag({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.icon,
    this.sortOrder = 0,
  });

  Color getColor(ColorIntensity palette) {
    final colors = AppColors.getAccentOptions(palette);
    return colors[colorIndex.clamp(0, colors.length - 1)];
  }

  Tag copyWith({
    String? id,
    String? name,
    int? colorIndex,
    IconData? icon,
    int? sortOrder,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
