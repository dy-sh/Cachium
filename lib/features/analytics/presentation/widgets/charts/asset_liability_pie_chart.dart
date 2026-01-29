import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/asset_liability_breakdown_provider.dart';

class AssetLiabilityPieChart extends ConsumerStatefulWidget {
  const AssetLiabilityPieChart({super.key});

  @override
  ConsumerState<AssetLiabilityPieChart> createState() =>
      _AssetLiabilityPieChartState();
}

class _AssetLiabilityPieChartState
    extends ConsumerState<AssetLiabilityPieChart>
    with SingleTickerProviderStateMixin {
  int touchedAssetIndex = -1;
  int touchedLiabilityIndex = -1;
  late AnimationController _animController;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _radiusAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(assetLiabilityBreakdownProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    final assetColor = AppColors.getTransactionColor('income', colorIntensity);
    final liabilityColor =
        AppColors.getTransactionColor('expense', colorIntensity);

    if (breakdown.assets.isEmpty && breakdown.liabilities.isEmpty) {
      return _buildEmptyState();
    }

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
          Text('Asset & Liability Breakdown', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.md),
          // Net worth summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Assets',
                  value: breakdown.totalAssets,
                  color: assetColor,
                  currencySymbol: currencySymbol,
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                _SummaryItem(
                  label: 'Liabilities',
                  value: breakdown.totalLiabilities,
                  color: liabilityColor,
                  currencySymbol: currencySymbol,
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                _SummaryItem(
                  label: 'Net Worth',
                  value: breakdown.netWorth,
                  color: breakdown.netWorth >= 0 ? assetColor : liabilityColor,
                  currencySymbol: currencySymbol,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Dual pie charts
          Row(
            children: [
              // Assets pie
              if (breakdown.assets.isNotEmpty)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Assets',
                        style: AppTypography.labelSmall.copyWith(
                          color: assetColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: AnimatedBuilder(
                          animation: _radiusAnimation,
                          builder: (context, child) {
                            return PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      setState(() => touchedAssetIndex = -1);
                                      return;
                                    }
                                    setState(() {
                                      touchedAssetIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                startDegreeOffset: -90,
                                sectionsSpace: 2,
                                centerSpaceRadius: 25,
                                sections: breakdown.assets
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final isTouched = index == touchedAssetIndex;
                                  final baseRadius = isTouched ? 25.0 : 20.0;

                                  return PieChartSectionData(
                                    color: item.color,
                                    value: item.balance,
                                    title: '',
                                    radius: baseRadius * _radiusAnimation.value,
                                    badgeWidget: isTouched
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.percentage.toStringAsFixed(0)}%',
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 9,
                                              ),
                                            ),
                                          )
                                        : null,
                                    badgePositionPercentageOffset: 1.3,
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              // Liabilities pie
              if (breakdown.liabilities.isNotEmpty)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Liabilities',
                        style: AppTypography.labelSmall.copyWith(
                          color: liabilityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: AnimatedBuilder(
                          animation: _radiusAnimation,
                          builder: (context, child) {
                            return PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      setState(
                                          () => touchedLiabilityIndex = -1);
                                      return;
                                    }
                                    setState(() {
                                      touchedLiabilityIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                startDegreeOffset: -90,
                                sectionsSpace: 2,
                                centerSpaceRadius: 25,
                                sections: breakdown.liabilities
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final isTouched =
                                      index == touchedLiabilityIndex;
                                  final baseRadius = isTouched ? 25.0 : 20.0;

                                  return PieChartSectionData(
                                    color: item.color,
                                    value: item.balance,
                                    title: '',
                                    radius: baseRadius * _radiusAnimation.value,
                                    badgeWidget: isTouched
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.percentage.toStringAsFixed(0)}%',
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 9,
                                              ),
                                            ),
                                          )
                                        : null,
                                    badgePositionPercentageOffset: 1.3,
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Legend
          if (breakdown.assets.isNotEmpty) ...[
            Text(
              'Assets',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...breakdown.assets.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _LegendRow(
                    color: item.color,
                    name: item.name,
                    percentage: item.percentage,
                    amount: item.balance,
                    currencySymbol: currencySymbol,
                  ),
                )),
          ],
          if (breakdown.liabilities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Liabilities',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...breakdown.liabilities.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _LegendRow(
                    color: item.color,
                    name: item.name,
                    percentage: item.percentage,
                    amount: item.balance,
                    currencySymbol: currencySymbol,
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
          Text('Asset & Liability Breakdown', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              'No accounts available',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String currencySymbol;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$currencySymbol${_formatCompact(value)}',
          style: AppTypography.moneyTiny.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String name;
  final double percentage;
  final double amount;
  final String currencySymbol;

  const _LegendRow({
    required this.color,
    required this.name,
    required this.percentage,
    required this.amount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: AppTypography.bodySmall.copyWith(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$currencySymbol${_formatCompact(amount)}',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
