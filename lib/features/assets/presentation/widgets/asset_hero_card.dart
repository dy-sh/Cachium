import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/asset.dart';
import '../../data/models/asset_category.dart';

class AssetHeroCard extends ConsumerWidget {
  final Asset asset;
  final Color assetColor;
  final double bgOpacity;
  final AssetCategory? assetCategory;

  const AssetHeroCard({
    super.key,
    required this.asset,
    required this.assetColor,
    required this.bgOpacity,
    this.assetCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: assetColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            assetColor.withValues(alpha: bgOpacity * 0.5),
            assetColor.withValues(alpha: bgOpacity * 0.2),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: assetColor.withValues(alpha: 0.9),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(
              asset.icon,
              color: AppColors.background,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: asset.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  asset.status.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: asset.status.color,
                  ),
                ),
              ),
              if (assetCategory != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: assetCategory!.getColor(intensity).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(assetCategory!.icon, size: 12, color: assetCategory!.getColor(intensity)),
                      const SizedBox(width: 4),
                      Text(
                        assetCategory!.name,
                        style: AppTypography.labelSmall.copyWith(
                          color: assetCategory!.getColor(intensity),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (asset.purchasePrice != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Purchased for ${CurrencyFormatter.format(asset.purchasePrice!, currencyCode: asset.purchaseCurrencyCode ?? ref.watch(mainCurrencyCodeProvider))}',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (asset.salePrice != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sold for ${CurrencyFormatter.format(asset.salePrice!, currencyCode: asset.saleCurrencyCode ?? ref.watch(mainCurrencyCodeProvider))}',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (asset.note != null && asset.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              asset.note!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              if (asset.purchaseDate != null)
                'Purchased ${DateFormatter.formatRelative(asset.purchaseDate!)}'
              else
                'Added ${DateFormatter.formatRelative(asset.createdAt)}',
              if (asset.soldDate != null)
                'Sold ${DateFormatter.formatRelative(asset.soldDate!)}',
            ].join('  \u00B7  '),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
