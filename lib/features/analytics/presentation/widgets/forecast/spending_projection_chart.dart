import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/forecast_projection_provider.dart';

class SpendingProjectionChart extends ConsumerWidget {
  const SpendingProjectionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projections = ref.watch(forecastProjectionProvider);
    final accentColor = ref.watch(accentColorProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (projections.isEmpty) return const SizedBox.shrink();

    // Split into actuals and projected
    final actuals = projections.where((p) => p.isActual).toList();
    final projected = projections.where((p) => !p.isActual).toList();

    // Build spots for actual spending
    final actualSpots = actuals.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.amount)).toList();

    // Build spots for projected (continuing from last actual)
    final projectedSpots = <FlSpot>[];
    if (actuals.isNotEmpty) {
      projectedSpots.add(FlSpot((actuals.length - 1).toDouble(), actuals.last.amount));
    }
    for (int i = 0; i < projected.length; i++) {
      projectedSpots.add(FlSpot((actuals.length + i).toDouble(), projected[i].amount));
    }

    // Confidence band spots
    final lowSpots = <FlSpot>[];
    final highSpots = <FlSpot>[];
    for (int i = 0; i < projected.length; i++) {
      final idx = (actuals.length + i).toDouble();
      lowSpots.add(FlSpot(idx, projected[i].lowerBound));
      highSpots.add(FlSpot(idx, projected[i].upperBound));
    }

    final allValues = projections.map((p) => p.amount).toList()
      ..addAll(projections.where((p) => !p.isActual).map((p) => p.upperBound))
      ..addAll(projections.where((p) => !p.isActual).map((p) => p.lowerBound));
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

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
              Text('Spending Projection', style: AppTypography.labelLarge),
              Row(
                children: [
                  _LegendDot(color: accentColor, label: 'Actual'),
                  const SizedBox(width: AppSpacing.sm),
                  _LegendDot(color: accentColor.withValues(alpha: 0.5), label: 'Projected', isDashed: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
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
                      interval: (projections.length / 6).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= projections.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            DateFormat('M/d').format(projections[index].date),
                            style: AppTypography.labelSmall,
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
                minX: 0,
                maxX: (projections.length - 1).toDouble(),
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  // Confidence band (high) - filled area between low and high
                  if (highSpots.isNotEmpty)
                    LineChartBarData(
                      spots: highSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: accentColor.withValues(alpha: 0.08),
                      ),
                    ),
                  if (lowSpots.isNotEmpty)
                    LineChartBarData(
                      spots: lowSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.surface, // cover up to make a band effect
                      ),
                    ),
                  // Actual line
                  if (actualSpots.isNotEmpty)
                    LineChartBarData(
                      spots: actualSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: accentColor,
                      barWidth: 2,
                      dotData: FlDotData(show: actualSpots.length <= 14),
                      belowBarData: BarAreaData(show: false),
                    ),
                  // Projected line (dashed)
                  if (projectedSpots.length > 1)
                    LineChartBarData(
                      spots: projectedSpots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: accentColor.withValues(alpha: 0.6),
                      barWidth: 2,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceLight,
                    tooltipRoundedRadius: AppRadius.sm,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        if (index < 0 || index >= projections.length) return null;
                        final p = projections[index];
                        final label = p.isActual ? 'Actual' : 'Projected';
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(p.date)}\n$label: $currencySymbol${p.amount.toStringAsFixed(0)}',
                          AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;
  const _LegendDot({required this.color, required this.label, this.isDashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
