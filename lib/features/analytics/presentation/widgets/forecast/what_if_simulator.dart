import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/category_breakdown.dart';
import '../../providers/category_breakdown_provider.dart';
import '../../providers/what_if_provider.dart';

class WhatIfSimulator extends ConsumerWidget {
  const WhatIfSimulator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdowns = ref.watch(categoryBreakdownProvider);
    final result = ref.watch(whatIfResultProvider);
    final adjustments = ref.watch(whatIfAdjustmentsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (breakdowns.isEmpty) return const SizedBox.shrink();

    // Top 6 categories by amount
    final topCategories = breakdowns.take(6).toList();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calculator, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('What-If Simulator', style: AppTypography.labelLarge),
                  ],
                ),
                if (adjustments.isNotEmpty)
                  GestureDetector(
                    onTap: () => ref.read(whatIfAdjustmentsProvider.notifier).resetAll(),
                    child: Text(
                      'Reset',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Result summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Projected Monthly Net', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                      Text(
                        '$currencySymbol${result.projectedMonthlyNet.toStringAsFixed(0)}',
                        style: AppTypography.moneySmall.copyWith(
                          color: result.projectedMonthlyNet >= 0 ? AppColors.green : AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (result.netChange != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (result.netChange > 0 ? AppColors.green : AppColors.red).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${result.netChange > 0 ? '+' : ''}$currencySymbol${result.netChange.toStringAsFixed(0)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: result.netChange > 0 ? AppColors.green : AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Category sliders
            ...topCategories.map((cat) => _CategorySlider(
              breakdown: cat,
              currencySymbol: currencySymbol,
              currentPercent: _getAdjustmentPercent(adjustments, cat.categoryId),
              onChanged: (value) {
                ref.read(whatIfAdjustmentsProvider.notifier).setAdjustment(
                  cat.categoryId,
                  cat.name,
                  value,
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  double _getAdjustmentPercent(List<dynamic> adjustments, String categoryId) {
    for (final adj in adjustments) {
      if (adj.categoryId == categoryId) return adj.percentChange;
    }
    return 0;
  }
}

class _CategorySlider extends StatelessWidget {
  final CategoryBreakdown breakdown;
  final String currencySymbol;
  final double currentPercent;
  final ValueChanged<double> onChanged;

  const _CategorySlider({
    required this.breakdown,
    required this.currencySymbol,
    required this.currentPercent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final adjustedAmount = breakdown.amount * (1 + currentPercent / 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  breakdown.name,
                  style: AppTypography.bodySmall.copyWith(color: breakdown.color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${currentPercent >= 0 ? '+' : ''}${currentPercent.toStringAsFixed(0)}%',
                style: AppTypography.labelSmall.copyWith(
                  color: currentPercent == 0
                      ? AppColors.textTertiary
                      : currentPercent > 0
                          ? AppColors.red
                          : AppColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$currencySymbol${adjustedAmount.toStringAsFixed(0)}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          SizedBox(
            height: 24,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: breakdown.color.withValues(alpha: 0.6),
                inactiveTrackColor: AppColors.border,
                thumbColor: breakdown.color,
                overlayColor: breakdown.color.withValues(alpha: 0.1),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: currentPercent,
                min: -50,
                max: 50,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
