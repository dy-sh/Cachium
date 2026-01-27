import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/spending_trends_provider.dart';

class SpendingTrendsSection extends ConsumerWidget {
  const SpendingTrendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(spendingTrendsProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (!trend.hasData) return const SizedBox.shrink();

    final incomeColor = AppColors.getTransactionColor('income', colorIntensity);
    final expenseColor = AppColors.getTransactionColor('expense', colorIntensity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending Trends', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'vs previous period',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Overall income/expense change with sparklines
            Row(
              children: [
                Expanded(
                  child: _TrendIndicator(
                    label: 'Income',
                    percent: trend.incomeChangePercent,
                    color: incomeColor,
                    history: trend.incomeHistory,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TrendIndicator(
                    label: 'Expenses',
                    percent: trend.expenseChangePercent,
                    color: expenseColor,
                    history: trend.expenseHistory,
                  ),
                ),
              ],
            ),
            if (trend.topCategoryChanges.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Top Category Changes',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...trend.topCategoryChanges.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat.categoryName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$currencySymbol${cat.currentAmount.toStringAsFixed(0)}',
                          style: AppTypography.moneyTiny,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _ChangeChip(
                          percent: cat.changePercent,
                          isIncrease: cat.isIncrease,
                          expenseColor: expenseColor,
                          incomeColor: incomeColor,
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  final List<double> history;

  const _TrendIndicator({
    required this.label,
    required this.percent,
    required this.color,
    this.history = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isUp = percent > 0;
    final arrow = isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (history.length >= 2)
                SizedBox(
                  width: 60,
                  height: 24,
                  child: _Sparkline(data: history, color: color),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(arrow, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${isUp ? '+' : ''}${percent.toStringAsFixed(1)}%',
                style: AppTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final double percent;
  final bool isIncrease;
  final Color expenseColor;
  final Color incomeColor;

  const _ChangeChip({
    required this.percent,
    required this.isIncrease,
    required this.expenseColor,
    required this.incomeColor,
  });

  @override
  Widget build(BuildContext context) {
    // For expenses: increase is bad (red), decrease is good (green)
    final color = isIncrease ? expenseColor : incomeColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.xsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIncrease ? LucideIcons.arrowUp : LucideIcons.arrowDown,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(0)}%',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
