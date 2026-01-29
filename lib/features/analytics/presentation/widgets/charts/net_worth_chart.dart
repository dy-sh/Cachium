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
import '../../providers/net_worth_history_provider.dart';

class NetWorthChart extends ConsumerWidget {
  const NetWorthChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyPoints = ref.watch(aggregatedNetWorthHistoryProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    final assetColor = AppColors.getTransactionColor('income', colorIntensity);
    final liabilityColor = AppColors.getTransactionColor('expense', colorIntensity);
    final netWorthColor = AppColors.cyan;

    if (historyPoints.isEmpty) {
      return _buildEmptyState();
    }

    // Build spots for all three lines
    final assetSpots = historyPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalAssets);
    }).toList();

    final liabilitySpots = historyPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalLiabilities);
    }).toList();

    final netWorthSpots = historyPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.netWorth);
    }).toList();

    // Calculate Y-axis range
    final allValues = [
      ...assetSpots.map((s) => s.y),
      ...liabilitySpots.map((s) => s.y),
      ...netWorthSpots.map((s) => s.y),
    ];
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    // Calculate net worth trend
    final firstNetWorth = historyPoints.first.netWorth;
    final lastNetWorth = historyPoints.last.netWorth;
    final trendPercent = firstNetWorth != 0
        ? ((lastNetWorth - firstNetWorth) / firstNetWorth.abs() * 100)
        : (lastNetWorth > 0 ? 100.0 : 0.0);
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
                    'Net Worth Over Time',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currencySymbol${lastNetWorth.toStringAsFixed(2)}',
                    style: AppTypography.moneySmall.copyWith(
                      color: lastNetWorth >= 0 ? assetColor : liabilityColor,
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
          const SizedBox(height: AppSpacing.md),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: assetColor, label: 'Assets'),
              const SizedBox(width: AppSpacing.lg),
              _LegendItem(color: liabilityColor, label: 'Liabilities'),
              const SizedBox(width: AppSpacing.lg),
              _LegendItem(color: netWorthColor, label: 'Net Worth'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                maxX: (historyPoints.length - 1).toDouble(),
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  // Assets line
                  LineChartBarData(
                    spots: assetSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: assetColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: assetColor.withValues(alpha: 0.1),
                    ),
                  ),
                  // Liabilities line
                  LineChartBarData(
                    spots: liabilitySpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: liabilityColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: liabilityColor.withValues(alpha: 0.1),
                    ),
                  ),
                  // Net Worth line (highlighted)
                  LineChartBarData(
                    spots: netWorthSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: netWorthColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: historyPoints.length <= 14,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: netWorthColor,
                          strokeWidth: 1,
                          strokeColor: AppColors.surface,
                        );
                      },
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
                        String label;
                        if (spot.barIndex == 0) {
                          label = 'Assets: $currencySymbol${point.totalAssets.toStringAsFixed(2)}';
                        } else if (spot.barIndex == 1) {
                          label = 'Liabilities: $currencySymbol${point.totalLiabilities.toStringAsFixed(2)}';
                        } else {
                          label = 'Net Worth: $currencySymbol${point.netWorth.toStringAsFixed(2)}';
                        }
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(point.date)}\n$label',
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
            'Net Worth Over Time',
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
