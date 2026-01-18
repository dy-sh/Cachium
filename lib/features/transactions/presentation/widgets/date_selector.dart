import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/inputs/fm_date_picker.dart';

/// A widget for selecting a date with quick options.
class DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const DateSelector({
    super.key,
    required this.date,
    required this.onChanged,
  });

  bool _isQuickDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);

    return DateFormatter.isSameDay(date, today) ||
        DateFormatter.isSameDay(date, yesterday) ||
        DateFormatter.isSameDay(date, monthStart);
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    HapticHelper.lightImpact();
    final picked = await showFMDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.chipGap,
          runSpacing: AppSpacing.chipGap,
          children: [
            _QuickDateChip(
              label: 'Today',
              isSelected: DateFormatter.isSameDay(date, today),
              onTap: () {
                HapticHelper.lightImpact();
                onChanged(today);
              },
            ),
            _QuickDateChip(
              label: 'Yesterday',
              isSelected: DateFormatter.isSameDay(date, yesterday),
              onTap: () {
                HapticHelper.lightImpact();
                onChanged(yesterday);
              },
            ),
            _QuickDateChip(
              label: 'Start of Month',
              isSelected: DateFormatter.isSameDay(date, monthStart),
              onTap: () {
                HapticHelper.lightImpact();
                onChanged(monthStart);
              },
            ),
            _QuickDateChip(
              label: 'Custom',
              isSelected: !_isQuickDate(date),
              onTap: () => _showCustomDatePicker(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => _showCustomDatePicker(context),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    DateFormatter.formatFull(date),
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectionGlow : AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPrimary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
