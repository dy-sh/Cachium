import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/analytics_filter.dart';
import '../../providers/analytics_filter_provider.dart';
import '../../providers/category_breakdown_provider.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  const CategoryPieChart({super.key});

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final breakdowns = ref.watch(categoryBreakdownProvider);
    final filter = ref.watch(analyticsFilterProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (breakdowns.isEmpty) {
      return _buildEmptyState(filter);
    }

    // Limit to top 6 categories, combine rest as "Other"
    final displayBreakdowns = _prepareChartData(breakdowns);

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
          Text(
            filter.typeFilter == AnalyticsTypeFilter.income
                ? 'Income by Category'
                : 'Spending by Category',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: displayBreakdowns.asMap().entries.map((entry) {
                      final index = entry.key;
                      final breakdown = entry.value;
                      final isTouched = index == touchedIndex;

                      return PieChartSectionData(
                        color: breakdown.color,
                        value: breakdown.amount,
                        title: '',
                        radius: isTouched ? 45 : 40,
                        badgeWidget: isTouched
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${breakdown.percentage.toStringAsFixed(1)}%',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : null,
                        badgePositionPercentageOffset: 1.2,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: displayBreakdowns.take(5).map((breakdown) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _LegendRow(
                        color: breakdown.color,
                        name: breakdown.name,
                        percentage: breakdown.percentage,
                        amount: breakdown.amount,
                        currencySymbol: currencySymbol,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_ChartData> _prepareChartData(List<dynamic> breakdowns) {
    if (breakdowns.length <= 6) {
      return breakdowns.map((b) => _ChartData(
        name: b.name,
        color: b.color,
        amount: b.amount,
        percentage: b.percentage,
      )).toList();
    }

    // Take top 5 and combine rest as "Other"
    final top5 = breakdowns.take(5).map((b) => _ChartData(
      name: b.name,
      color: b.color,
      amount: b.amount,
      percentage: b.percentage,
    )).toList();

    final otherAmount = breakdowns.skip(5).fold(0.0, (sum, b) => sum + b.amount);
    final otherPercentage = breakdowns.skip(5).fold(0.0, (sum, b) => sum + b.percentage);

    top5.add(_ChartData(
      name: 'Other',
      color: AppColors.textTertiary,
      amount: otherAmount,
      percentage: otherPercentage,
    ));

    return top5;
  }

  Widget _buildEmptyState(AnalyticsFilter filter) {
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
          Text(
            filter.typeFilter == AnalyticsTypeFilter.income
                ? 'Income by Category'
                : 'Spending by Category',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              'No data available',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _ChartData {
  final String name;
  final Color color;
  final double amount;
  final double percentage;

  const _ChartData({
    required this.name,
    required this.color,
    required this.amount,
    required this.percentage,
  });
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String name;
  final double percentage;
  final double amount;
  final String currencySymbol;

  const _LegendRow({
    required this.color,
    required this.name,
    required this.percentage,
    required this.amount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: AppTypography.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
