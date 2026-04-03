import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// Header shown during multi-select mode with bulk action controls.
class SelectionHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onChangeCategory;
  final VoidCallback onChangeAccount;

  const SelectionHeader({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.onSelectAll,
    required this.onDelete,
    required this.onChangeCategory,
    required this.onChangeAccount,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.iconButton,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.x,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$selectedCount selected',
              style: AppTypography.h2,
            ),
          ),
          GestureDetector(
            onTap: hasSelection ? onChangeCategory : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.iconButton,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.tag,
                color: hasSelection ? AppColors.textPrimary : AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: hasSelection ? onChangeAccount : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.iconButton,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.wallet,
                color: hasSelection ? AppColors.textPrimary : AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onSelectAll,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.iconButton,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.checkSquare,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: hasSelection ? onDelete : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasSelection
                    ? AppColors.red.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: AppRadius.iconButton,
                border: Border.all(
                  color: hasSelection
                      ? AppColors.red.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                LucideIcons.trash2,
                color: hasSelection ? AppColors.red : AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for items displayed in the bulk picker bottom sheet.
class BulkPickerItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const BulkPickerItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Bottom sheet for picking a category or account during bulk operations.
class BulkPickerSheet extends StatelessWidget {
  final String title;
  final List<BulkPickerItem> items;

  const BulkPickerSheet({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textTertiary,
            borderRadius: AppRadius.xxsAll,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => Navigator.pop(context, item.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: AppRadius.smAll,
                        ),
                        child: Icon(item.icon, color: item.color, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(item.name, style: AppTypography.labelLarge),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
      ],
    );
  }
}
