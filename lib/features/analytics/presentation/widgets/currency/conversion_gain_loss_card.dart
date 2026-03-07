import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/conversion_gain_loss_provider.dart';

class ConversionGainLossCard extends ConsumerWidget {
  const ConversionGainLossCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(conversionGainLossProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);

    if (data.totalGainLoss.abs() < 0.01) return const SizedBox.shrink();

    final isPositive = data.totalGainLoss > 0;
    final color = isPositive
        ? AppColors.getTransactionColor('income', intensity)
        : AppColors.getTransactionColor('expense', intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final sign = isPositive ? '+' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: bgOpacity),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Currency Impact', style: AppTypography.h4),
              const Spacer(),
              Text(
                '$sign${CurrencyFormatter.format(data.totalGainLoss, currencyCode: mainCurrency)}',
                style: AppTypography.moneyMedium.copyWith(color: color),
              ),
            ],
          ),
          if (data.byCurrency.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            ...data.byCurrency.entries.map((entry) {
              final currencySign = entry.value > 0 ? '+' : '';
              final entryColor = entry.value > 0
                  ? AppColors.getTransactionColor('income', intensity)
                  : AppColors.getTransactionColor('expense', intensity);
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Text(
                      entry.key,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$currencySign${CurrencyFormatter.format(entry.value, currencyCode: mainCurrency)}',
                      style: AppTypography.bodySmall.copyWith(color: entryColor),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
