import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../data/models/spending_profile.dart';

class RadarSpendingChart extends StatefulWidget {
  final List<SpendingProfile> profiles;
  final List<Color> profileColors;
  final String currencySymbol;

  const RadarSpendingChart({
    super.key,
    required this.profiles,
    required this.profileColors,
    this.currencySymbol = '\$',
  });

  @override
  State<RadarSpendingChart> createState() => _RadarSpendingChartState();
}

class _RadarSpendingChartState extends State<RadarSpendingChart> {
  int? _touchedDataSetIndex;
  int? _touchedEntryIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty || widget.profiles.first.axes.isEmpty) return _buildEmptyState();

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
              Text('Spending Profile', style: AppTypography.labelLarge),
              Row(
                children: widget.profiles.asMap().entries.map((entry) {
                  final color = entry.key < widget.profileColors.length ? widget.profileColors[entry.key] : AppColors.textSecondary;
                  return Padding(
                    padding: EdgeInsets.only(left: entry.key > 0 ? AppSpacing.sm : 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(entry.value.label, style: AppTypography.labelSmall.copyWith(color: color)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_touchedDataSetIndex != null && _touchedEntryIndex != null)
            _buildTooltip(),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: AppTypography.labelSmall.copyWith(color: Colors.transparent),
                tickBorderData: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                gridBorderData: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.15,
                getTitle: (index, angle) {
                  if (widget.profiles.isEmpty || index >= widget.profiles.first.axes.length) {
                    return RadarChartTitle(text: '');
                  }
                  return RadarChartTitle(
                    text: widget.profiles.first.axes[index].categoryName,
                    angle: 0,
                  );
                },
                dataSets: widget.profiles.asMap().entries.map((entry) {
                  final color = entry.key < widget.profileColors.length ? widget.profileColors[entry.key] : AppColors.textSecondary;
                  return RadarDataSet(
                    fillColor: color.withValues(alpha: 0.15),
                    borderColor: color,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: entry.value.axes.map((axis) => RadarEntry(value: axis.value)).toList(),
                  );
                }).toList(),
                titleTextStyle: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                radarTouchData: RadarTouchData(
                  enabled: true,
                  touchSpotThreshold: 20,
                  touchCallback: (event, response) {
                    setState(() {
                      if (response == null || response.touchedSpot == null) {
                        if (event is FlTapUpEvent || event is FlLongPressEnd || event is FlPanEndEvent) {
                          _touchedDataSetIndex = null;
                          _touchedEntryIndex = null;
                        }
                        return;
                      }
                      _touchedDataSetIndex = response.touchedSpot!.touchedDataSetIndex;
                      _touchedEntryIndex = response.touchedSpot!.touchedRadarEntryIndex;
                    });
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

  Widget _buildTooltip() {
    final dsIndex = _touchedDataSetIndex!;
    final entryIndex = _touchedEntryIndex!;

    if (dsIndex >= widget.profiles.length) return const SizedBox.shrink();
    final profile = widget.profiles[dsIndex];
    if (entryIndex >= profile.axes.length) return const SizedBox.shrink();

    final axis = profile.axes[entryIndex];
    final color = dsIndex < widget.profileColors.length ? widget.profileColors[dsIndex] : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        '${axis.categoryName}: ${_formatAmount(axis.rawAmount)}',
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value.abs() >= 1000000) return '${widget.currencySymbol}${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${widget.currencySymbol}${(value / 1000).toStringAsFixed(1)}K';
    return '${widget.currencySymbol}${value.toStringAsFixed(0)}';
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
          Text('Spending Profile', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xxl),
          Center(child: Text('No data available', style: AppTypography.bodySmall)),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
