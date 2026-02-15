import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../settings/data/models/app_settings.dart';

enum AssetStatus { active, sold }

extension AssetStatusExtension on AssetStatus {
  String get displayName {
    switch (this) {
      case AssetStatus.active:
        return 'Active';
      case AssetStatus.sold:
        return 'Sold';
    }
  }

  Color get color {
    switch (this) {
      case AssetStatus.active:
        return AppColors.income;
      case AssetStatus.sold:
        return AppColors.textSecondary;
    }
  }

  IconData get icon {
    switch (this) {
      case AssetStatus.active:
        return LucideIcons.checkCircle;
      case AssetStatus.sold:
        return LucideIcons.circleOff;
    }
  }
}

class Asset {
  final String id;
  final String name;
  final IconData icon;
  final int colorIndex;
  final AssetStatus status;
  final String? note;
  final DateTime createdAt;

  const Asset({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    this.status = AssetStatus.active,
    this.note,
    required this.createdAt,
  });

  Color getColor(ColorIntensity intensity) {
    return AppColors.getAccentColor(colorIndex, intensity);
  }

  Asset copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? colorIndex,
    AssetStatus? status,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      status: status ?? this.status,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Asset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
