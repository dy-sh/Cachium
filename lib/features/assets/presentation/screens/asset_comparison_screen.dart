import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/asset.dart';
import '../providers/asset_analytics_providers.dart';
import '../providers/assets_provider.dart';

class AssetComparisonScreen extends ConsumerStatefulWidget {
  const AssetComparisonScreen({super.key});

  @override
  ConsumerState<AssetComparisonScreen> createState() => _AssetComparisonScreenState();
}

class _AssetComparisonScreenState extends ConsumerState<AssetComparisonScreen> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final allAssets = ref.watch(assetsProvider).valueOrNull ?? [];
    final intensity = ref.watch(colorIntensityProvider);
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Compare Assets',
              onClose: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                children: [
                  // Asset picker
                  Text('Select up to 3 assets to compare', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: allAssets.map((asset) {
                      final isSelected = _selectedIds.contains(asset.id);
                      final assetColor = asset.getColor(intensity);
                      final bgOpacity = AppColors.getBgOpacity(intensity);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(asset.id);
                            } else if (_selectedIds.length < 3) {
                              _selectedIds.add(asset.id);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: isSelected ? assetColor.withValues(alpha: bgOpacity) : AppColors.surface,
                            borderRadius: AppRadius.smAll,
                            border: Border.all(
                              color: isSelected ? assetColor : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                asset.icon,
                                size: 14,
                                color: isSelected ? assetColor : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                asset.name,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected ? assetColor : AppColors.textSecondary,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                Icon(LucideIcons.check, size: 12, color: assetColor),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_selectedIds.length >= 2) ...[
                    const SizedBox(height: AppSpacing.xl),
                    // Comparison table
                    _ComparisonTable(
                      assetIds: _selectedIds.toList(),
                      intensity: intensity,
                      mainCurrency: mainCurrency,
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    Center(
                      child: Text(
                        'Select at least 2 assets',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonTable extends ConsumerWidget {
  final List<String> assetIds;
  final ColorIntensity intensity;
  final String mainCurrency;

  const _ComparisonTable({
    required this.assetIds,
    required this.intensity,
    required this.mainCurrency,
  });

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    if (days < 30) return '${days}d';
    final months = days ~/ 30;
    if (months < 12) return '${months}mo';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '${years}y';
    return '${years}y ${remainingMonths}mo';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = assetIds
        .map((id) => ref.watch(assetByIdProvider(id)))
        .where((a) => a != null)
        .cast<Asset>()
        .toList();

    if (assets.length < 2) return const SizedBox.shrink();

    // Gather data
    final data = assets.map((asset) {
      final breakdown = ref.watch(assetCostBreakdownProvider(asset.id));
      final stats = ref.watch(assetStatsProvider(asset.id));
      final netCost = ref.watch(assetNetCostProvider(asset.id));
      final txCount = ref.watch(assetTransactionCountProvider(asset.id));
      final roi = ref.watch(assetROIProvider(asset.id));
      return (
        asset: asset,
        breakdown: breakdown,
        stats: stats,
        netCost: netCost,
        txCount: txCount,
        roi: roi,
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header row with asset names
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 100), // label column
                ...data.map((d) => Expanded(
                  child: Column(
                    children: [
                      Icon(d.asset.icon, size: 20, color: d.asset.getColor(intensity)),
                      const SizedBox(height: 4),
                      Text(
                        d.asset.name,
                        style: AppTypography.labelSmall,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

          // Comparison rows
          _ComparisonRow(
            label: 'Purchase',
            values: data.map((d) => d.asset.purchasePrice != null
                ? CurrencyFormatter.format(d.asset.purchasePrice!, currencyCode: mainCurrency)
                : '-').toList(),
          ),
          _ComparisonRow(
            label: 'Acquisition',
            values: data.map((d) =>
                CurrencyFormatter.format(d.breakdown.acquisitionCost, currencyCode: mainCurrency)).toList(),
            isAlternate: true,
          ),
          _ComparisonRow(
            label: 'Running Costs',
            values: data.map((d) =>
                CurrencyFormatter.format(d.breakdown.runningCosts, currencyCode: mainCurrency)).toList(),
          ),
          _ComparisonRow(
            label: 'Revenue',
            values: data.map((d) =>
                CurrencyFormatter.format(d.breakdown.revenue, currencyCode: mainCurrency)).toList(),
            isAlternate: true,
          ),
          _ComparisonRow(
            label: 'Net Cost',
            values: data.map((d) =>
                CurrencyFormatter.format(d.netCost.abs(), currencyCode: mainCurrency)).toList(),
            valueColors: data.map((d) => d.netCost > 0
                ? AppColors.getTransactionColor('expense', intensity)
                : AppColors.getTransactionColor('income', intensity)).toList(),
          ),
          _ComparisonRow(
            label: 'Monthly Avg',
            values: data.map((d) =>
                CurrencyFormatter.format(d.stats.monthlyAverage, currencyCode: mainCurrency)).toList(),
            isAlternate: true,
          ),
          _ComparisonRow(
            label: 'Per Day',
            values: data.map((d) =>
                CurrencyFormatter.format(d.stats.costPerDay, currencyCode: mainCurrency)).toList(),
          ),
          _ComparisonRow(
            label: 'Time Owned',
            values: data.map((d) => _formatDuration(d.stats.timeOwned)).toList(),
            isAlternate: true,
          ),
          _ComparisonRow(
            label: 'Transactions',
            values: data.map((d) => '${d.txCount}').toList(),
          ),
          if (data.any((d) => d.roi != null))
            _ComparisonRow(
              label: 'ROI',
              values: data.map((d) => d.roi != null
                  ? '${d.roi! >= 0 ? '+' : ''}${d.roi!.toStringAsFixed(1)}%'
                  : '-').toList(),
              valueColors: data.map((d) {
                if (d.roi == null) return AppColors.textTertiary;
                return d.roi! >= 0
                    ? AppColors.getTransactionColor('income', intensity)
                    : AppColors.getTransactionColor('expense', intensity);
              }).toList(),
              isAlternate: true,
            ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final List<Color>? valueColors;
  final bool isAlternate;

  const _ComparisonRow({
    required this.label,
    required this.values,
    this.valueColors,
    this.isAlternate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: isAlternate ? AppColors.background.withValues(alpha: 0.5) : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ...values.asMap().entries.map((e) => Expanded(
            child: Text(
              e.value,
              style: AppTypography.bodySmall.copyWith(
                color: valueColors != null ? valueColors![e.key] : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }
}
