import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/data/models/app_settings.dart';
import '../../../data/models/category_time_series.dart';

class StackedAreaChart extends StatefulWidget {
  final List<CategoryTimeSeries> seriesList;
  final ColorIntensity colorIntensity;
  final String currencySymbol;
  final String? highlightedCategoryId;

  const StackedAreaChart({
    super.key,
    required this.seriesList,
    required this.colorIntensity,
    required this.currencySymbol,
    this.highlightedCategoryId,
  });

  @override
  State<StackedAreaChart> createState() => _StackedAreaChartState();
}

class _StackedAreaChartState extends State<StackedAreaChart> {
  final Set<int> _hiddenSeriesIndices = {};

  List<CategoryTimeSeries> get _visibleSeries {
    return [
      for (int i = 0; i < widget.seriesList.length; i++)
        if (!_hiddenSeriesIndices.contains(i)) widget.seriesList[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.seriesList.isEmpty) return _buildEmptyState();

    final accentColors = AppColors.getAccentOptions(widget.colorIntensity);
    final pointCount = widget.seriesList.first.points.length;
    final visibleSeries = _visibleSeries;
    final stackedMax = _computeStackedMax(visibleSeries);

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
          const SizedBox(height: AppSpacing.sm),
          _buildLegend(accentColors),
          const SizedBox(height: AppSpacing.md),
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
                          child: Text(widget.seriesList.first.points[idx].label, style: AppTypography.labelSmall),
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
                lineBarsData: _buildStackedLines(visibleSeries, accentColors),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    tooltipBorder: BorderSide(color: AppColors.border),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final seriesIndex = spot.barIndex;
                        if (seriesIndex < 0 || seriesIndex >= visibleSeries.length) {
                          return null;
                        }
                        final series = visibleSeries[seriesIndex];
                        final color = accentColors[series.colorIndex.clamp(0, accentColors.length - 1)];
                        final pointIdx = spot.x.toInt();
                        final rawAmount = pointIdx >= 0 && pointIdx < series.points.length
                            ? series.points[pointIdx].amount
                            : 0.0;
                        return LineTooltipItem(
                          '${series.name}: ${_formatAmount(rawAmount)}',
                          AppTypography.labelSmall.copyWith(color: color),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<Color> accentColors) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: List.generate(widget.seriesList.length, (i) {
        final s = widget.seriesList[i];
        final color = accentColors[s.colorIndex.clamp(0, accentColors.length - 1)];
        final isHidden = _hiddenSeriesIndices.contains(i);
        final isHighlighted = widget.highlightedCategoryId != null &&
            widget.highlightedCategoryId == s.categoryId;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isHidden) {
                _hiddenSeriesIndices.remove(i);
              } else {
                _hiddenSeriesIndices.add(i);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: isHighlighted ? Border.all(color: color, width: 1.5) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isHidden ? Colors.transparent : color,
                    border: Border.all(color: isHidden ? AppColors.textSecondary : color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  s.name,
                  style: AppTypography.labelSmall.copyWith(
                    color: isHidden ? AppColors.textSecondary : null,
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  List<LineChartBarData> _buildStackedLines(List<CategoryTimeSeries> series, List<Color> accentColors) {
    if (series.isEmpty) return [];
    final result = <LineChartBarData>[];
    final pointCount = series.first.points.length;
    final cumulativeValues = List.generate(pointCount, (_) => 0.0);

    for (int i = series.length - 1; i >= 0; i--) {
      final s = series[i];
      final color = accentColors[s.colorIndex.clamp(0, accentColors.length - 1)];

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

  double _computeStackedMax(List<CategoryTimeSeries> series) {
    if (series.isEmpty) return 1;
    final pointCount = series.first.points.length;
    double maxVal = 0;
    for (int j = 0; j < pointCount; j++) {
      double sum = 0;
      for (final s in series) {
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
    if (value.abs() >= 1000000) return '${widget.currencySymbol}${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${widget.currencySymbol}${(value / 1000).toStringAsFixed(0)}K';
    return '${widget.currencySymbol}${value.toStringAsFixed(0)}';
  }
}
