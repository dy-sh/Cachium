import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/data/models/app_settings.dart';
import '../../../data/models/category_time_series.dart';

class StackedAreaChart extends StatelessWidget {
  final List<CategoryTimeSeries> seriesList;
  final ColorIntensity colorIntensity;
  final String currencySymbol;

  const StackedAreaChart({
    super.key,
    required this.seriesList,
    required this.colorIntensity,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (seriesList.isEmpty) return _buildEmptyState();

    final accentColors = AppColors.getAccentOptions(colorIntensity);
    final pointCount = seriesList.first.points.length;

    // Compute stacked values
    final stackedMax = _computeStackedMax();

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
          Text('Category Proportions', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: stackedMax * 1.1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: stackedMax > 0 ? stackedMax / 4 : 1,
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
                        if (idx < 0 || idx >= pointCount) return const SizedBox.shrink();
                        if (pointCount > 12 && idx % 2 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(seriesList.first.points[idx].label, style: AppTypography.labelSmall),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        _formatAmount(value),
                        style: AppTypography.labelSmall,
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: _buildStackedLines(accentColors),
                lineTouchData: const LineTouchData(enabled: false),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> _buildStackedLines(List<Color> accentColors) {
    final result = <LineChartBarData>[];
    final pointCount = seriesList.first.points.length;

    // Build cumulative stacks (bottom to top)
    final cumulativeValues = List.generate(pointCount, (_) => 0.0);

    for (int i = seriesList.length - 1; i >= 0; i--) {
      final s = seriesList[i];
      final color = accentColors[s.colorIndex.clamp(0, accentColors.length - 1)];

      // Add current series values to cumulative
      final spots = <FlSpot>[];
      for (int j = 0; j < pointCount; j++) {
        cumulativeValues[j] += s.points[j].amount;
        spots.add(FlSpot(j.toDouble(), cumulativeValues[j]));
      }

      result.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 1.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.3),
        ),
      ));
    }

    return result.reversed.toList();
  }

  double _computeStackedMax() {
    if (seriesList.isEmpty) return 1;
    final pointCount = seriesList.first.points.length;
    double maxVal = 0;
    for (int j = 0; j < pointCount; j++) {
      double sum = 0;
      for (final s in seriesList) {
        sum += s.points[j].amount;
      }
      if (sum > maxVal) maxVal = sum;
    }
    return maxVal == 0 ? 1 : maxVal;
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
          Text('Category Proportions', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xxl),
          Center(child: Text('Select categories to compare', style: AppTypography.bodySmall)),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value.abs() >= 1000000) return '$currencySymbol${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '$currencySymbol${(value / 1000).toStringAsFixed(0)}K';
    return '$currencySymbol${value.toStringAsFixed(0)}';
  }
}
