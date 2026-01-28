import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/spending_patterns_provider.dart';

class SpendingHeatmap extends ConsumerWidget {
  const SpendingHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(spendingPatternsProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (patterns.isEmpty) return const SizedBox.shrink();

    final maxAvg = patterns.fold(0.0, (m, d) => d.average > m ? d.average : m);
    if (maxAvg == 0) return const SizedBox.shrink();

    final expenseColor = AppColors.getTransactionColor('expense', colorIntensity);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by Day of Week', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: patterns.map((day) {
              final intensity = maxAvg > 0 ? day.average / maxAvg : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: expenseColor.withValues(
                            alpha: 0.1 + (intensity * 0.7),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: intensity > 0.3
                              ? Text(
                                  '$currencySymbol${day.average.toStringAsFixed(0)}',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 8,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.name,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
