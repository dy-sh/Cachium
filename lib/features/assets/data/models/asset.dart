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
  final DateTime? soldDate;
  final String? note;
  final double? purchasePrice;
  final String? purchaseCurrencyCode;
  final String? assetCategoryId;
  final int sortOrder;
  final DateTime createdAt;

  const Asset({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    this.status = AssetStatus.active,
    this.soldDate,
    this.note,
    this.purchasePrice,
    this.purchaseCurrencyCode,
    this.assetCategoryId,
    this.sortOrder = 0,
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
    DateTime? soldDate,
    bool clearSoldDate = false,
    String? note,
    bool clearNote = false,
    double? purchasePrice,
    bool clearPurchasePrice = false,
    String? purchaseCurrencyCode,
    bool clearPurchaseCurrencyCode = false,
    String? assetCategoryId,
    bool clearAssetCategoryId = false,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      status: status ?? this.status,
      soldDate: clearSoldDate ? null : (soldDate ?? this.soldDate),
      note: clearNote ? null : (note ?? this.note),
      purchasePrice: clearPurchasePrice ? null : (purchasePrice ?? this.purchasePrice),
      purchaseCurrencyCode: clearPurchaseCurrencyCode ? null : (purchaseCurrencyCode ?? this.purchaseCurrencyCode),
      assetCategoryId: clearAssetCategoryId ? null : (assetCategoryId ?? this.assetCategoryId),
      sortOrder: sortOrder ?? this.sortOrder,
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
