import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/merchant_analysis_provider.dart';

class TopMerchantsChart extends ConsumerWidget {
  final int limit;

  const TopMerchantsChart({
    super.key,
    this.limit = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(merchantAnalysisProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final colorIntensity = ref.watch(colorIntensityProvider);

    if (summary.topMerchants.isEmpty) {
      return const SizedBox.shrink();
    }

    final merchants = summary.topMerchants.take(limit).toList();
    final maxAmount = merchants.first.totalAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: merchants.map((merchant) {
        final category = merchant.primaryCategoryId != null
            ? categories.firstWhere(
                (c) => c.id == merchant.primaryCategoryId,
                orElse: () => categories.first,
              )
            : null;

        final categoryColors = AppColors.getCategoryColors(colorIntensity);
        final barColor = category != null
            ? categoryColors[category.colorIndex % categoryColors.length]
            : AppColors.purple;

        final barWidth = merchant.totalAmount / maxAmount;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      merchant.merchant,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    CurrencyFormatter.format(merchant.totalAmount),
                    style: AppTypography.moneySmall.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: barWidth,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${merchant.transactionCount} transactions',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'avg ${CurrencyFormatter.format(merchant.averageTransaction)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
