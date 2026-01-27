import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../data/models/spending_profile.dart';

class RadarSpendingChart extends StatelessWidget {
  final List<SpendingProfile> profiles;
  final List<Color> profileColors;

  const RadarSpendingChart({
    super.key,
    required this.profiles,
    required this.profileColors,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty || profiles.first.axes.isEmpty) return _buildEmptyState();

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
                children: profiles.asMap().entries.map((entry) {
                  final color = entry.key < profileColors.length ? profileColors[entry.key] : AppColors.textSecondary;
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
                  if (profiles.isEmpty || index >= profiles.first.axes.length) {
                    return RadarChartTitle(text: '');
                  }
                  return RadarChartTitle(
                    text: profiles.first.axes[index].categoryName,
                    angle: 0,
                  );
                },
                dataSets: profiles.asMap().entries.map((entry) {
                  final color = entry.key < profileColors.length ? profileColors[entry.key] : AppColors.textSecondary;
                  return RadarDataSet(
                    fillColor: color.withValues(alpha: 0.15),
                    borderColor: color,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: entry.value.axes.map((axis) => RadarEntry(value: axis.value)).toList(),
                  );
                }).toList(),
                titleTextStyle: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
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
          Text('Spending Profile', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xxl),
          Center(child: Text('No data available', style: AppTypography.bodySmall)),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
