import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/budget_forecast_provider.dart';

class BudgetForecastCards extends ConsumerWidget {
  const BudgetForecastCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecasts = ref.watch(budgetForecastProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (forecasts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(
        top: AppSpacing.cardPadding,
        bottom: AppSpacing.cardPadding,
        left: AppSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Forecast', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: forecasts.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              padding: const EdgeInsets.only(right: AppSpacing.cardPadding),
              itemBuilder: (context, index) {
                final f = forecasts[index];
                final riskColor = f.overagePercent > 20
                    ? AppColors.red
                    : f.overagePercent > 0
                        ? AppColors.yellow
                        : AppColors.green;
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.categoryName,
                        style: AppTypography.labelMedium.copyWith(color: f.categoryColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: f.budgetAmount > 0
                              ? (f.currentSpending / f.budgetAmount).clamp(0.0, 1.0)
                              : 0.0,
                          backgroundColor: AppColors.border,
                          color: riskColor,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$currencySymbol${f.currentSpending.toStringAsFixed(0)} / $currencySymbol${f.budgetAmount.toStringAsFixed(0)}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Projected',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            '$currencySymbol${f.projectedSpending.toStringAsFixed(0)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: riskColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (f.daysRemaining > 0)
                        Text(
                          '${f.daysRemaining}d remaining',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
