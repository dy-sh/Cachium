import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';

class ComparativeBarGroup {
  final String label;
  final List<double> values;
  const ComparativeBarGroup({required this.label, required this.values});
}

class ComparativeBarSeries {
  final String name;
  final Color color;
  const ComparativeBarSeries({required this.name, required this.color});
}

class ComparativeBarChart extends StatefulWidget {
  final String title;
  final List<ComparativeBarSeries> series;
  final List<ComparativeBarGroup> groups;
  final String currencySymbol;

  const ComparativeBarChart({
    super.key,
    required this.title,
    required this.series,
    required this.groups,
    required this.currencySymbol,
  });

  @override
  State<ComparativeBarChart> createState() => _ComparativeBarChartState();
}

class _ComparativeBarChartState extends State<ComparativeBarChart> {
  final Set<int> _hiddenSeriesIndices = {};

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return _buildEmptyState();

    double maxY = 0;
    for (final g in widget.groups) {
      for (int i = 0; i < g.values.length; i++) {
        if (_hiddenSeriesIndices.contains(i)) continue;
        if (g.values[i] > maxY) maxY = g.values[i];
      }
    }
    if (maxY == 0) maxY = 1;

    final barWidth = widget.series.length <= 2 ? 10.0 : 7.0;

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
              Text(widget.title, style: AppTypography.labelLarge),
              Flexible(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: widget.series.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
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
                        child: _LegendDot(color: s.color, label: s.name),
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
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.1,
                barGroups: widget.groups.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: List.generate(widget.series.length, (i) {
                      final hidden = _hiddenSeriesIndices.contains(i);
                      return BarChartRodData(
                        toY: hidden ? 0 : (i < entry.value.values.length ? entry.value.values[i] : 0),
                        color: widget.series[i].color,
                        width: barWidth,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      );
                    }),
                  );
                }).toList(),
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
                        if (idx < 0 || idx >= widget.groups.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(widget.groups[idx].label, style: AppTypography.labelSmall, overflow: TextOverflow.ellipsis),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        _formatAmount(value, widget.currencySymbol),
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
                      final seriesName = rodIndex < widget.series.length ? widget.series[rodIndex].name : '';
                      return BarTooltipItem(
                        '$seriesName\n${widget.currencySymbol}${rod.toY.toStringAsFixed(2)}',
                        AppTypography.bodySmall.copyWith(color: rod.color),
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
          Text(widget.title, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xxl),
          Center(child: Text('No data available', style: AppTypography.bodySmall)),
          const SizedBox(height: AppSpacing.xxl),
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
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
