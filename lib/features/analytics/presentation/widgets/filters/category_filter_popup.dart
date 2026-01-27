import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/analytics_filter_provider.dart';
import 'category_filter_sheet.dart';

class CategoryFilterPopup extends ConsumerWidget {
  const CategoryFilterPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final accentColor = ref.watch(accentColorProvider);

    final hasFilter = filter.hasCategoryFilter;
    final count = filter.selectedCategoryIds.length;

    return GestureDetector(
      onTap: () => _showCategoryFilterSheet(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: hasFilter ? accentColor.withOpacity(0.1) : AppColors.surface,
          borderRadius: AppRadius.chip,
          border: Border.all(
            color: hasFilter ? accentColor : AppColors.border,
            width: hasFilter ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.filter,
              size: 14,
              color: hasFilter ? accentColor : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              hasFilter ? 'Categories ($count)' : 'Categories',
              style: AppTypography.labelMedium.copyWith(
                color: hasFilter ? accentColor : AppColors.textPrimary,
                fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                LucideIcons.x,
                size: 12,
                color: accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCategoryFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CategoryFilterSheet(),
    );
  }
}
