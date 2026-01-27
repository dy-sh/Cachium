import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/category_time_series_provider.dart';
import '../charts/category_lines_chart.dart';
import '../charts/stacked_area_chart.dart';

class CategoryComparisonSection extends ConsumerWidget {
  const CategoryComparisonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(selectedComparisonCategoryIdsProvider);
    final seriesList = ref.watch(categoryTimeSeriesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    final categories = categoriesAsync.valueOrNull;
    // Only show root-level expense categories for selection
    final selectableCategories = categories
        ?.where((c) => c.parentId == null && c.type == CategoryType.expense)
        .toList() ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Comparison', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('Select 2-5 categories', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: AppSpacing.sm),

            // Category chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: selectableCategories.map((cat) {
                final isSelected = selectedIds.contains(cat.id);
                return _ToggleChip(
                  label: cat.name,
                  selected: isSelected,
                  onTap: () {
                    final current = Set<String>.from(selectedIds);
                    if (isSelected) {
                      current.remove(cat.id);
                    } else if (current.length < 5) {
                      current.add(cat.id);
                    }
                    ref.read(selectedComparisonCategoryIdsProvider.notifier).state = current;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Charts
            CategoryLinesChart(
              seriesList: seriesList,
              colorIntensity: colorIntensity,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: AppSpacing.md),
            StackedAreaChart(
              seriesList: seriesList,
              colorIntensity: colorIntensity,
              currencySymbol: currencySymbol,
            ),

            // Summary stats
            if (seriesList.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Summary', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              ...seriesList.map((s) {
                final accentColors = AppColors.getAccentOptions(colorIntensity);
                final color = accentColors[s.colorIndex.clamp(0, accentColors.length - 1)];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(s.name, style: AppTypography.labelSmall.copyWith(color: color))),
                      Text(
                        '$currencySymbol${_formatCompact(s.total)}',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary.withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.accentPrimary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.accentPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
