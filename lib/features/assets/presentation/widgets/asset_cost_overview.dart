import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/asset.dart';
import '../providers/asset_analytics_providers.dart';
import '../providers/assets_provider.dart';

class AssetCostOverview extends ConsumerWidget {
  final String assetId;
  final Color assetColor;
  final double bgOpacity;

  const AssetCostOverview({
    super.key,
    required this.assetId,
    required this.assetColor,
    required this.bgOpacity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(assetByIdProvider(assetId));
    final costBreakdown = ref.watch(assetCostBreakdownProvider(assetId));
    final roi = ref.watch(assetROIProvider(assetId));
    final intensity = ref.watch(colorIntensityProvider);
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: assetColor.withValues(alpha: bgOpacity * 0.3),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: assetColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Total Cost of Ownership',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                CurrencyFormatter.format(
                  costBreakdown.acquisitionCost + costBreakdown.runningCosts,
                  currencyCode: mainCurrency,
                ),
                style: AppTypography.moneyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (costBreakdown.revenue > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'After income: ${CurrencyFormatter.format(costBreakdown.netCost.abs(), currencyCode: mainCurrency)} ${costBreakdown.netCost > 0 ? 'net cost' : 'net gain'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (costBreakdown.acquisitionCost > 0) ...[
          Row(
            children: [
              Expanded(
                child: _CostCard(
                  label: 'Acquisition',
                  amount: costBreakdown.acquisitionCost,
                  color: AppColors.getTransactionColor('expense', intensity),
                  currencyCode: mainCurrency,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CostCard(
                  label: 'Running Costs',
                  amount: costBreakdown.runningCosts,
                  color: AppColors.getTransactionColor('expense', intensity),
                  currencyCode: mainCurrency,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _CostCard(
                  label: 'Total Expenses',
                  amount: costBreakdown.runningCosts,
                  color: AppColors.getTransactionColor('expense', intensity),
                  currencyCode: mainCurrency,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Expanded(
              child: _CostCard(
                label: asset?.status == AssetStatus.sold ? 'Sale & Income' : 'Income',
                amount: costBreakdown.revenue,
                color: AppColors.getTransactionColor('income', intensity),
                currencyCode: mainCurrency,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CostCard(
                label: 'Net Cost',
                amount: costBreakdown.netCost.abs(),
                color: costBreakdown.netCost > 0
                    ? AppColors.getTransactionColor('expense', intensity)
                    : AppColors.getTransactionColor('income', intensity),
                currencyCode: mainCurrency,
              ),
            ),
          ],
        ),
        if (costBreakdown.profitLoss != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _CostCard(
                  label: costBreakdown.profitLoss! >= 0 ? 'Profit on Sale' : 'Loss on Sale',
                  amount: costBreakdown.profitLoss!.abs(),
                  color: costBreakdown.profitLoss! >= 0
                      ? AppColors.getTransactionColor('income', intensity)
                      : AppColors.getTransactionColor('expense', intensity),
                  currencyCode: mainCurrency,
                ),
              ),
              if (roi != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROI',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%',
                          style: AppTypography.moneySmall.copyWith(
                            color: roi >= 0
                                ? AppColors.getTransactionColor('income', intensity)
                                : AppColors.getTransactionColor('expense', intensity),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
        if (costBreakdown.revenueFromSalePrice)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: AppColors.accentPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Revenue is based on the sale price. Create a sale transaction for more accurate tracking.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CostCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currencyCode;

  const _CostCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(amount, currencyCode: currencyCode),
            style: AppTypography.moneySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
