import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/income_expense_summary_provider.dart';

class TrendExtrapolationSection extends ConsumerWidget {
  const TrendExtrapolationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ref.watch(periodSummariesProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (periods.length < 2) return const SizedBox.shrink();

    final incomeColor = AppColors.getTransactionColor('income', colorIntensity);
    final expenseColor = AppColors.getTransactionColor('expense', colorIntensity);

    // Build actual spots
    final incomeSpots = periods.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.income)).toList();
    final expenseSpots = periods.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.expense)).toList();

    // Simple linear extrapolation: use last 3 points to project 2 more
    final projCount = 2;
    final incomeProjected = _extrapolate(incomeSpots, projCount);
    final expenseProjected = _extrapolate(expenseSpots, projCount);

    final allValues = [
      ...incomeSpots.map((s) => s.y),
      ...expenseSpots.map((s) => s.y),
      ...incomeProjected.map((s) => s.y),
      ...expenseProjected.map((s) => s.y),
    ];
    final maxY = allValues.isEmpty ? 1.0 : allValues.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trend Extrapolation', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 1,
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
                          if (idx < 0 || idx >= periods.length) {
                            if (idx >= periods.length && idx < periods.length + projCount) {
                              return Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text('+${idx - periods.length + 1}', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(periods[idx].label, style: AppTypography.labelSmall),
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
                  maxY: maxY * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: incomeColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    if (incomeProjected.length > 1)
                      LineChartBarData(
                        spots: incomeProjected,
                        isCurved: true,
                        color: incomeColor.withValues(alpha: 0.4),
                        barWidth: 2,
                        dashArray: [6, 4],
                        dotData: const FlDotData(show: false),
                      ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: expenseColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    if (expenseProjected.length > 1)
                      LineChartBarData(
                        spots: expenseProjected,
                        isCurved: true,
                        color: expenseColor.withValues(alpha: 0.4),
                        barWidth: 2,
                        dashArray: [6, 4],
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surfaceLight,
                      tooltipRoundedRadius: AppRadius.sm,
                    ),
                    handleBuiltInTouches: true,
                  ),
                ),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _extrapolate(List<FlSpot> spots, int count) {
    if (spots.length < 2) return [];
    // Use last 3 points for slope
    final n = spots.length >= 3 ? 3 : 2;
    final recent = spots.sublist(spots.length - n);
    final slope = (recent.last.y - recent.first.y) / (recent.last.x - recent.first.x);

    final result = <FlSpot>[spots.last];
    for (int i = 1; i <= count; i++) {
      result.add(FlSpot(
        spots.last.x + i,
        (spots.last.y + slope * i).clamp(0, double.infinity),
      ));
    }
    return result;
  }

  String _formatAmount(double value, String symbol) {
    if (value.abs() >= 1000000) return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '$symbol${(value / 1000).toStringAsFixed(0)}K';
    return '$symbol${value.toStringAsFixed(0)}';
  }
}
