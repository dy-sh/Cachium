import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/asset_analytics_providers.dart';

class AssetCategoryBreakdown extends ConsumerWidget {
  final String assetId;

  const AssetCategoryBreakdown({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(assetCategoryBreakdownProvider(assetId));
    final intensity = ref.watch(colorIntensityProvider);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    if (categories.isEmpty) return const SizedBox.shrink();

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
          Text('Expense Categories', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.md),
          ...categories.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: entry.color.withValues(alpha: bgOpacity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    entry.icon,
                    color: entry.color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.name,
                            style: AppTypography.labelMedium,
                          ),
                          Text(
                            CurrencyFormatter.format(entry.amount),
                            style: AppTypography.moneySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: entry.percentage,
                          backgroundColor: AppColors.border,
                          color: entry.color,
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
