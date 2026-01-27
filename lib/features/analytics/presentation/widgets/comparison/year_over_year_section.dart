import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/data/models/app_settings.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/year_over_year_summary.dart';
import '../../providers/year_over_year_provider.dart';

class YearOverYearSection extends ConsumerWidget {
  const YearOverYearSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(yearOverYearDataProvider);
    final grouping = ref.watch(yoyGroupingProvider);
    final selectedYears = ref.watch(yoySelectedYearsProvider);
    final availableYears = ref.watch(yoyAvailableYearsProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

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
            Text('Year-over-Year', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),
            // Grouping toggle
            Row(
              children: [
                _ToggleChip(
                  label: 'Monthly',
                  selected: grouping == YoYGrouping.monthly,
                  onTap: () => ref.read(yoyGroupingProvider.notifier).state = YoYGrouping.monthly,
                ),
                const SizedBox(width: AppSpacing.sm),
                _ToggleChip(
                  label: 'Quarterly',
                  selected: grouping == YoYGrouping.quarterly,
                  onTap: () => ref.read(yoyGroupingProvider.notifier).state = YoYGrouping.quarterly,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Year selector
            if (availableYears.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: availableYears.map((year) {
                  final isSelected = selectedYears.contains(year);
                  return _ToggleChip(
                    label: '$year',
                    selected: isSelected,
                    onTap: () {
                      final current = Set<int>.from(selectedYears);
                      if (isSelected) {
                        current.remove(year);
                      } else {
                        current.add(year);
                      }
                      ref.read(yoySelectedYearsProvider.notifier).state = current;
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.lg),
            if (data.isEmpty || selectedYears.isEmpty)
              _buildEmptyState()
            else ...[
              _buildChart(data, grouping, colorIntensity, currencySymbol),
              const SizedBox(height: AppSpacing.lg),
              _buildSummaryTable(data, colorIntensity, currencySymbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Text('No data available', style: AppTypography.bodySmall),
      ),
    );
  }

  Widget _buildChart(
    List<YearOverYearSummary> data,
    YoYGrouping grouping,
    ColorIntensity colorIntensity,
    String currencySymbol,
  ) {
    final periodCount = grouping == YoYGrouping.monthly ? 12 : 4;
    final labels = grouping == YoYGrouping.monthly
        ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        : ['Q1', 'Q2', 'Q3', 'Q4'];

    // Compute maxY across all periods
    double maxY = 0;
    for (final yearData in data) {
      for (final p in yearData.periods) {
        final v = p.income > p.expense ? p.income : p.expense;
        if (v > maxY) maxY = v;
      }
    }
    if (maxY == 0) maxY = 1;

    final barWidth = data.length <= 2 ? 8.0 : 6.0;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.1,
          barGroups: List.generate(periodCount, (periodIdx) {
            return BarChartGroupData(
              x: periodIdx,
              barRods: data.asMap().entries.map((entry) {
                final yearIdx = entry.key;
                final yearData = entry.value;
                final period = yearData.periods[periodIdx];
                final color = AppColors.getAccentColor(yearIdx + 1, colorIntensity);
                return BarChartRodData(
                  toY: period.net.abs() > 0 ? period.net.abs() : (period.income + period.expense),
                  color: color,
                  width: barWidth,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                );
              }).toList(),
            );
          }),
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
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  if (grouping == YoYGrouping.monthly && idx % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(labels[idx], style: AppTypography.labelSmall),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatAmount(value, currencySymbol),
                    style: AppTypography.labelSmall,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceLight,
              tooltipRoundedRadius: AppRadius.sm,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (rodIndex >= data.length) return null;
                final year = data[rodIndex].year;
                return BarTooltipItem(
                  '$year\n$currencySymbol${rod.toY.toStringAsFixed(2)}',
                  AppTypography.bodySmall.copyWith(color: rod.color),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTable(
    List<YearOverYearSummary> data,
    ColorIntensity colorIntensity,
    String currencySymbol,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        // Header row
        Row(
          children: [
            const Expanded(flex: 2, child: SizedBox()),
            ...data.map((d) => Expanded(
              flex: 2,
              child: Text(
                '${d.year}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.getAccentColor(data.indexOf(d) + 1, colorIntensity),
                ),
                textAlign: TextAlign.right,
              ),
            )),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _summaryRow('Income', data.map((d) => d.totalIncome).toList(), currencySymbol),
        _summaryRow('Expense', data.map((d) => d.totalExpense).toList(), currencySymbol),
        _summaryRow('Net', data.map((d) => d.totalNet).toList(), currencySymbol),
        // % change row
        if (data.length >= 2) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('% Change', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
              ),
              const Expanded(flex: 2, child: SizedBox()), // first year has no comparison
              ...data.skip(1).map((d) {
                final prevIdx = data.indexOf(d) - 1;
                final prev = data[prevIdx].totalNet;
                final change = prev != 0 ? ((d.totalNet - prev) / prev.abs() * 100) : 0.0;
                final isPositive = change >= 0;
                return Expanded(
                  flex: 2,
                  child: Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: isPositive ? AppColors.green : AppColors.red,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, List<double> values, String currencySymbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
          ),
          ...values.map((v) => Expanded(
            flex: 2,
            child: Text(
              '$currencySymbol${_formatCompact(v)}',
              style: AppTypography.labelSmall,
              textAlign: TextAlign.right,
            ),
          )),
        ],
      ),
    );
  }

  String _formatAmount(double value, String symbol) {
    if (value.abs() >= 1000000) return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '$symbol${(value / 1000).toStringAsFixed(0)}K';
    return '$symbol${value.toStringAsFixed(0)}';
  }

  String _formatCompact(double value) {
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary.withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.accentPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
