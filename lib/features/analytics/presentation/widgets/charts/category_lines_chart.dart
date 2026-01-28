import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/data/models/app_settings.dart';
import '../../../data/models/category_time_series.dart';

class CategoryLinesChart extends StatefulWidget {
  final List<CategoryTimeSeries> seriesList;
  final ColorIntensity colorIntensity;
  final String currencySymbol;

  const CategoryLinesChart({
    super.key,
    required this.seriesList,
    required this.colorIntensity,
    required this.currencySymbol,
  });

  @override
  State<CategoryLinesChart> createState() => _CategoryLinesChartState();
}

class _CategoryLinesChartState extends State<CategoryLinesChart> {
  final Set<int> _hiddenSeriesIndices = {};

  @override
  Widget build(BuildContext context) {
    if (widget.seriesList.isEmpty) return _buildEmptyState();

    final accentColors = AppColors.getAccentOptions(widget.colorIntensity);

    double maxY = 0;
    for (int i = 0; i < widget.seriesList.length; i++) {
      if (_hiddenSeriesIndices.contains(i)) continue;
      for (final p in widget.seriesList[i].points) {
        if (p.amount > maxY) maxY = p.amount;
      }
    }
    if (maxY == 0) maxY = 1;

    final pointCount = widget.seriesList.first.points.length;

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
              Text('Category Trends', style: AppTypography.labelLarge),
              Flexible(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: widget.seriesList.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final color = accentColors[s.colorIndex.clamp(0, accentColors.length - 1)];
                    final hidden = _hiddenSeriesIndices.contains(i);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (hidden) {
                            _hiddenSeriesIndices.remove(i);
                          } else {
                            _hiddenSeriesIndices.add(i);
                          }
                        });
                      },
                      child: AnimatedOpacity(
                        opacity: hidden ? 0.3 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(s.name, style: AppTypography.labelSmall.copyWith(color: color)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.1,
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
                lineBarsData: widget.seriesList.asMap().entries
                    .where((entry) => !_hiddenSeriesIndices.contains(entry.key))
                    .map((entry) {
                  final s = entry.value;
                  final color = accentColors[s.colorIndex.clamp(0, accentColors.length - 1)];
                  return LineChartBarData(
                    spots: s.points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: pointCount <= 14,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceLight,
                    tooltipRoundedRadius: AppRadius.sm,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final seriesIdx = spot.barIndex;
                        final visibleIndices = widget.seriesList.asMap().entries
                            .where((e) => !_hiddenSeriesIndices.contains(e.key))
                            .map((e) => e.key)
                            .toList();
                        final actualIdx = seriesIdx < visibleIndices.length ? visibleIndices[seriesIdx] : seriesIdx;
                        final name = actualIdx < widget.seriesList.length ? widget.seriesList[actualIdx].name : '';
                        return LineTooltipItem(
                          '$name\n${widget.currencySymbol}${spot.y.toStringAsFixed(2)}',
                          AppTypography.bodySmall.copyWith(color: spot.bar.color),
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
          Text('Category Trends', style: AppTypography.labelLarge),
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
