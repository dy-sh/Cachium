import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../settings/data/models/app_settings.dart';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final int colorIndex;
  final IconData icon;
  final String? linkedAccountId;
  final DateTime? targetDate;
  final String? note;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.colorIndex,
    this.icon = LucideIcons.piggyBank,
    this.linkedAccountId,
    this.targetDate,
    this.note,
    required this.createdAt,
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  bool get isCompleted => currentAmount >= targetAmount;

  Color getColor(ColorIntensity intensity) {
    return AppColors.getAccentColor(colorIndex, intensity);
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    int? colorIndex,
    IconData? icon,
    String? linkedAccountId,
    bool clearLinkedAccountId = false,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      colorIndex: colorIndex ?? this.colorIndex,
      icon: icon ?? this.icon,
      linkedAccountId:
          clearLinkedAccountId ? null : (linkedAccountId ?? this.linkedAccountId),
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavingsGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
