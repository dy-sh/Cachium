import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/chart_drill_down.dart';
import '../../providers/drill_down_provider.dart';
import '../../providers/waterfall_provider.dart';
import '../../../data/models/waterfall_entry.dart';

class WaterfallChart extends ConsumerWidget {
  const WaterfallChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(waterfallProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (entries.isEmpty) return const SizedBox.shrink();

    // Find the range for Y axis
    double minY = 0;
    double maxY = 0;
    for (final e in entries) {
      final top = e.type == WaterfallEntryType.netTotal
          ? e.runningTotal
          : (e.amount > 0 ? e.runningTotal : e.runningTotal - e.amount.abs());
      final bottom = e.type == WaterfallEntryType.netTotal
          ? 0.0
          : (e.amount > 0 ? e.runningTotal - e.amount : e.runningTotal);
      if (top > maxY) maxY = top;
      if (bottom < minY) minY = bottom;
    }
    if (maxY == 0) maxY = 1;
    final range = maxY - minY;

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
          Text('Income to Expenses Waterfall', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.1,
                minY: minY < 0 ? minY * 1.1 : 0,
                barGroups: entries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;

                  double fromY;
                  double toY;
                  if (e.type == WaterfallEntryType.netTotal) {
                    fromY = 0;
                    toY = e.runningTotal;
                  } else if (e.amount > 0) {
                    fromY = e.runningTotal - e.amount;
                    toY = e.runningTotal;
                  } else {
                    fromY = e.runningTotal;
                    toY = e.runningTotal - e.amount.abs();
                  }

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        fromY: fromY,
                        toY: toY,
                        color: e.color,
                        width: entries.length > 6 ? 16 : 24,
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
                  horizontalInterval: range > 0 ? range / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            entries[idx].label,
                            style: AppTypography.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        _formatAmount(value, currencySymbol),
                        style: AppTypography.labelSmall,
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceLight,
                    tooltipRoundedRadius: AppRadius.sm,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final e = entries[groupIndex];
                      return BarTooltipItem(
                        '${e.label}\n$currencySymbol${e.amount.toStringAsFixed(2)}',
                        AppTypography.bodySmall.copyWith(color: e.color),
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (event is FlTapUpEvent &&
                        barTouchResponse != null &&
                        barTouchResponse.spot != null) {
                      final groupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                      if (groupIndex >= 0 && groupIndex < entries.length) {
                        final e = entries[groupIndex];
                        if (e.type != WaterfallEntryType.netTotal) {
                          ref.read(drillDownProvider.notifier).state = ChartDrillDown(
                            transactionType: e.type == WaterfallEntryType.income ? 'income' : 'expense',
                          );
                        }
                      }
                    }
                  },
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
    if (value.abs() >= 1000000) return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '$symbol${(value / 1000).toStringAsFixed(0)}K';
    return '$symbol${value.toStringAsFixed(0)}';
  }
}
