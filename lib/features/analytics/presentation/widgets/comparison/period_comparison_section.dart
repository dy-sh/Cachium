import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/date_range_preset.dart';
import '../../providers/period_comparison_provider.dart';
import '../../providers/spending_profile_provider.dart';
import '../charts/comparative_bar_chart.dart';
import '../charts/radar_spending_chart.dart';

class PeriodComparisonSection extends ConsumerWidget {
  const PeriodComparisonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(periodComparisonDataProvider);
    final periodA = ref.watch(comparisonPeriodAProvider);
    final periodB = ref.watch(comparisonPeriodBProvider);
    final profiles = ref.watch(spendingProfileProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    final incomeColor = AppColors.getTransactionColor('income', colorIntensity);
    final expenseColor = AppColors.getTransactionColor('expense', colorIntensity);

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
            Text('Period Comparison', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),

            // Period selectors
            Row(
              children: [
                Expanded(
                  child: _PeriodSelector(
                    label: 'Period A',
                    range: periodA,
                    color: AppColors.accentPrimary,
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDateRange: DateTimeRange(start: periodA.start, end: periodA.end),
                      );
                      if (picked != null) {
                        ref.read(comparisonPeriodAProvider.notifier).state = DateRange(
                          start: picked.start,
                          end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PeriodSelector(
                    label: 'Period B',
                    range: periodB,
                    color: AppColors.yellow,
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDateRange: DateTimeRange(start: periodB.start, end: periodB.end),
                      );
                      if (picked != null) {
                        ref.read(comparisonPeriodBProvider.notifier).state = DateRange(
                          start: picked.start,
                          end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Summary cards
            _SummaryRow(
              label: 'Income',
              valueA: data.periodA.income,
              valueB: data.periodB.income,
              currencySymbol: currencySymbol,
              color: incomeColor,
            ),
            const SizedBox(height: AppSpacing.xs),
            _SummaryRow(
              label: 'Expense',
              valueA: data.periodA.expense,
              valueB: data.periodB.expense,
              currencySymbol: currencySymbol,
              color: expenseColor,
            ),
            const SizedBox(height: AppSpacing.xs),
            _SummaryRow(
              label: 'Net',
              valueA: data.periodA.net,
              valueB: data.periodB.net,
              currencySymbol: currencySymbol,
              color: AppColors.accentPrimary,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Comparative bar chart
            ComparativeBarChart(
              title: 'Period Overview',
              series: [
                ComparativeBarSeries(name: 'Period A', color: AppColors.accentPrimary),
                ComparativeBarSeries(name: 'Period B', color: AppColors.yellow),
              ],
              groups: [
                ComparativeBarGroup(label: 'Income', values: [data.periodA.income, data.periodB.income]),
                ComparativeBarGroup(label: 'Expense', values: [data.periodA.expense, data.periodB.expense]),
                ComparativeBarGroup(label: 'Net', values: [data.periodA.net.abs(), data.periodB.net.abs()]),
              ],
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: AppSpacing.md),

            // Radar chart
            RadarSpendingChart(
              profiles: profiles,
              profileColors: [AppColors.accentPrimary, AppColors.yellow],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category table
            if (data.categoryComparison.isNotEmpty) ...[
              Text('Category Breakdown', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: AppRadius.xsAll,
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox()),
                    Expanded(flex: 2, child: Text('Period A', style: AppTypography.labelSmall.copyWith(color: AppColors.accentPrimary), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Period B', style: AppTypography.labelSmall.copyWith(color: AppColors.yellow), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Change', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...data.categoryComparison.asMap().entries.map((entry) {
                final item = entry.value;
                final change = item.changePercent;
                final isPositive = change >= 0;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.key.isOdd ? AppColors.surfaceLight.withValues(alpha: 0.3) : Colors.transparent,
                    borderRadius: AppRadius.xsAll,
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(item.name, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 2, child: Text('$currencySymbol${_formatCompact(item.amountA)}', style: AppTypography.labelSmall, textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('$currencySymbol${_formatCompact(item.amountB)}', style: AppTypography.labelSmall, textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text(
                        '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                        style: AppTypography.labelSmall.copyWith(color: isPositive ? AppColors.green : AppColors.red),
                        textAlign: TextAlign.right,
                      )),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _PeriodSelector extends StatelessWidget {
  final String label;
  final DateRange range;
  final Color color;
  final VoidCallback onTap;
  const _PeriodSelector({required this.label, required this.range, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('MMM d').format(range.start)} - ${DateFormat('MMM d').format(range.end)}',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double valueA;
  final double valueB;
  final String currencySymbol;
  final Color color;
  const _SummaryRow({required this.label, required this.valueA, required this.valueB, required this.currencySymbol, required this.color});

  @override
  Widget build(BuildContext context) {
    final change = valueA != 0 ? ((valueB - valueA) / valueA.abs() * 100) : (valueB > 0 ? 100 : 0);
    final isPositive = change >= 0;
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTypography.labelSmall.copyWith(color: color))),
        Expanded(flex: 2, child: Text('$currencySymbol${_fmt(valueA)}', style: AppTypography.labelSmall, textAlign: TextAlign.right)),
        Expanded(flex: 2, child: Text('$currencySymbol${_fmt(valueB)}', style: AppTypography.labelSmall, textAlign: TextAlign.right)),
        Expanded(flex: 1, child: Text(
          '${isPositive ? '+' : ''}${change.toStringAsFixed(0)}%',
          style: AppTypography.labelSmall.copyWith(color: isPositive ? AppColors.green : AppColors.red, fontSize: 10),
          textAlign: TextAlign.right,
        )),
      ],
    );
  }

  String _fmt(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
