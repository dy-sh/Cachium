import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/asset_analytics_providers.dart';

class AssetSpendingChart extends ConsumerWidget {
  final String assetId;

  const AssetSpendingChart({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyData = ref.watch(assetMonthlySpendingProvider(assetId));
    final intensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (monthlyData.length < 2) return const SizedBox.shrink();

    final incomeColor = AppColors.getTransactionColor('income', intensity);
    final expenseColor = AppColors.getTransactionColor('expense', intensity);

    final maxValue = monthlyData.fold<double>(0, (max, d) {
      final periodMax = d.expense > d.income ? d.expense : d.income;
      return periodMax > max ? periodMax : max;
    });

    final monthFormat = DateFormat('MMM');

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Spending', style: AppTypography.labelLarge),
              Row(
                children: [
                  _LegendDot(color: expenseColor, label: 'Expense'),
                  const SizedBox(width: AppSpacing.sm),
                  _LegendDot(color: incomeColor, label: 'Income'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.1,
                barGroups: monthlyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.expense,
                        color: expenseColor,
                        width: monthlyData.length > 12 ? 6 : 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: data.income,
                        color: incomeColor,
                        width: monthlyData.length > 12 ? 6 : 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 3 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthlyData.length) {
                          return const SizedBox.shrink();
                        }
                        if (monthlyData.length > 12 && index % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            monthFormat.format(monthlyData[index].month),
                            style: AppTypography.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatAmount(value, currencySymbol),
                          style: AppTypography.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceLight,
                    tooltipRoundedRadius: AppRadius.sm,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isExpense = rodIndex == 0;
                      return BarTooltipItem(
                        '${isExpense ? 'Expense' : 'Income'}\n$currencySymbol${rod.toY.toStringAsFixed(2)}',
                        AppTypography.bodySmall.copyWith(
                          color: isExpense ? expenseColor : incomeColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value, String symbol) {
    if (value.abs() >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(0)}K';
    }
    return '$symbol${value.toStringAsFixed(0)}';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
