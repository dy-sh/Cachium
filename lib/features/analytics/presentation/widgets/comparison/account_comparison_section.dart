import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/account_comparison.dart';
import '../../providers/account_comparison_provider.dart';
import '../charts/comparative_bar_chart.dart';

class AccountComparisonSection extends ConsumerWidget {
  const AccountComparisonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(selectedComparisonAccountIdsProvider);
    final comparisonData = ref.watch(accountComparisonDataProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    final accounts = accountsAsync.valueOrNull ?? [];

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
            Text('Account Comparison', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),

            // Account chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: accounts.map((acct) {
                final isSelected = selectedIds.contains(acct.id);
                return _ToggleChip(
                  label: acct.name,
                  selected: isSelected,
                  onTap: () {
                    final current = Set<String>.from(selectedIds);
                    if (isSelected) {
                      current.remove(acct.id);
                    } else {
                      current.add(acct.id);
                    }
                    ref.read(selectedComparisonAccountIdsProvider.notifier).state = current;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            if (comparisonData.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(child: Text('Select accounts to compare', style: AppTypography.bodySmall)),
              )
            else ...[
              // Balance trend lines
              _buildBalanceTrends(comparisonData, currencySymbol),
              const SizedBox(height: AppSpacing.md),

              // Income/Expense bar chart
              ComparativeBarChart(
                title: 'Income & Expense by Account',
                series: comparisonData.map((d) => ComparativeBarSeries(name: d.name, color: d.color)).toList(),
                groups: [
                  ComparativeBarGroup(
                    label: 'Income',
                    values: comparisonData.map((d) => d.totalIncome).toList(),
                  ),
                  ComparativeBarGroup(
                    label: 'Expense',
                    values: comparisonData.map((d) => d.totalExpense).toList(),
                  ),
                ],
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Summary table
              Text('Summary', style: AppTypography.labelMedium),
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
                    Expanded(flex: 2, child: Text('Income', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Expense', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Net', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...comparisonData.asMap().entries.map((entry) {
                final d = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.key.isOdd ? AppColors.surfaceLight.withValues(alpha: 0.3) : Colors.transparent,
                    borderRadius: AppRadius.xsAll,
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(d.name, style: AppTypography.labelSmall, overflow: TextOverflow.ellipsis)),
                        ],
                      )),
                      Expanded(flex: 2, child: Text('$currencySymbol${_fmt(d.totalIncome)}', style: AppTypography.labelSmall, textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('$currencySymbol${_fmt(d.totalExpense)}', style: AppTypography.labelSmall, textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text(
                        '$currencySymbol${_fmt(d.net)}',
                        style: AppTypography.labelSmall.copyWith(color: d.net >= 0 ? AppColors.green : AppColors.red),
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

  Widget _buildBalanceTrends(List<AccountComparisonData> data, String currencySymbol) {
    if (data.isEmpty || data.first.balanceHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final d in data) {
      for (final p in d.balanceHistory) {
        if (p.balance < minY) minY = p.balance;
        if (p.balance > maxY) maxY = p.balance;
      }
    }
    if (minY == maxY) { minY -= 1; maxY += 1; }
    final range = maxY - minY;

    final pointCount = data.first.balanceHistory.length;

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
            children: [
              Text('Balance Trends', style: AppTypography.labelLarge),
              const Spacer(),
              ...data.map((d) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(d.name, style: AppTypography.labelSmall.copyWith(color: d.color)),
                  ],
                ),
              )),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY - range * 0.1,
                maxY: maxY + range * 0.1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: range > 0 ? range / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [5, 5]),
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
                          child: Text(data.first.balanceHistory[idx].label, style: AppTypography.labelSmall),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(_fmtAxis(value, currencySymbol), style: AppTypography.labelSmall),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: data.map((d) {
                  return LineChartBarData(
                    spots: d.balanceHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.balance)).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: d.color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceLight,
                    tooltipRoundedRadius: AppRadius.sm,
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

  String _fmt(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtAxis(double value, String symbol) {
    if (value.abs() >= 1000000) return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '$symbol${(value / 1000).toStringAsFixed(0)}K';
    return '$symbol${value.toStringAsFixed(0)}';
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary.withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.accentPrimary : AppColors.border),
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
