import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/balance_history_provider.dart';

class BalanceLineChart extends ConsumerWidget {
  const BalanceLineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyPoints = ref.watch(aggregatedBalanceHistoryProvider);
    final accentColor = ref.watch(accentColorProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (historyPoints.isEmpty) {
      return _buildEmptyState();
    }

    final spots = historyPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalBalance);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    // Trend calculation: first→last point percentage change
    final firstBalance = historyPoints.first.totalBalance;
    final lastBalance = historyPoints.last.totalBalance;
    final trendPercent = firstBalance != 0
        ? ((lastBalance - firstBalance) / firstBalance.abs() * 100)
        : (lastBalance > 0 ? 100.0 : 0.0);
    final trendIsUp = trendPercent >= 0;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Over Time',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currencySymbol${lastBalance.toStringAsFixed(2)}',
                    style: AppTypography.moneySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (trendIsUp ? AppColors.green : AppColors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendIsUp
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 12,
                      color: trendIsUp ? AppColors.green : AppColors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trendIsUp ? '+' : ''}${trendPercent.toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: trendIsUp ? AppColors.green : AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: range > 0 ? range / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _calculateInterval(historyPoints.length),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= historyPoints.length) {
                          return const SizedBox.shrink();
                        }
                        final date = historyPoints[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: AppTypography.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
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
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: accentColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 14,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: accentColor,
                          strokeWidth: 1,
                          strokeColor: AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withValues(alpha: 0.3),
                          accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceLight,
                    tooltipRoundedRadius: AppRadius.sm,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        if (index < 0 || index >= historyPoints.length) {
                          return null;
                        }
                        final point = historyPoints[index];
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(point.date)}\n$currencySymbol${point.totalBalance.toStringAsFixed(2)}',
                          AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
              duration: const Duration(milliseconds: 600),
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
          Text(
            'Balance Over Time',
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

  double _calculateInterval(int dataPoints) {
    if (dataPoints <= 7) return 1;
    if (dataPoints <= 14) return 2;
    if (dataPoints <= 30) return 5;
    return (dataPoints / 6).roundToDouble();
  }

  String _formatAmount(double value, String symbol) {
    if (value.abs() >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${value.toStringAsFixed(0)}';
  }
}
