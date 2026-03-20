import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/transactions_provider.dart';

class CategoryFilterSheet extends ConsumerWidget {
  const CategoryFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final filter = ref.watch(advancedTransactionFilterProvider);
    final selected = filter.selectedCategoryIds;
    final intensity = ref.watch(colorIntensityProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.xxsAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter by Category', style: AppTypography.h4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => ref.read(advancedTransactionFilterProvider.notifier)
                          .setCategories(categories.map((c) => c.id).toSet()),
                      child: Text('Select All', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: () => ref.read(advancedTransactionFilterProvider.notifier).setCategories({}),
                      child: Text('Clear', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                child: Column(
                  children: categories.map((category) {
                    final isSelected = selected.contains(category.id);
                    return GestureDetector(
                      onTap: () => ref.read(advancedTransactionFilterProvider.notifier).toggleCategory(category.id),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: category.getColor(intensity).withValues(alpha: 0.15),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: Center(
                                child: Icon(category.icon, size: 16, color: category.getColor(intensity)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                category.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(LucideIcons.check, size: 18, color: AppColors.textPrimary),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
