import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/net_worth_snapshot_provider.dart';

class NetWorthHistoryScreen extends ConsumerWidget {
  const NetWorthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(netWorthSnapshotsProvider);
    final mainCurrencyCode = ref.watch(mainCurrencyCodeProvider);
    final currencySymbol = Currency.symbolFromCode(mainCurrencyCode);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final trend = ref.watch(netWorthTrendProvider);

    final holdingColor = AppColors.getTransactionColor('income', colorIntensity);
    final liabilityColor = AppColors.getTransactionColor('expense', colorIntensity);
    final netWorthColor = AppColors.cyan;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Net Worth History'),
            Expanded(
              child: snapshotsAsync.when(
                loading: () => const Center(child: LoadingIndicator()),
                error: (e, _) => Center(
                  child: Text('Error loading snapshots', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ),
                data: (snapshots) {
                  if (snapshots.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.trendingUp, size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'No snapshots yet',
                              style: AppTypography.h4.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Monthly snapshots are recorded automatically. Check back next month.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final currentNetWorth = snapshots.last.netWorth;
                  final trendIsUp = (trend ?? 0) >= 0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),

                        // Current net worth card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.card,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Current Net Worth', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$currencySymbol${_formatNumber(currentNetWorth)}',
                                    style: AppTypography.h3.copyWith(
                                      color: currentNetWorth >= 0 ? holdingColor : liabilityColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (trend != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (trendIsUp ? AppColors.green : AppColors.red).withValues(alpha: 0.1),
                                    borderRadius: AppRadius.mdAll,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        trendIsUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                                        size: 14,
                                        color: trendIsUp ? AppColors.green : AppColors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${trendIsUp ? '+' : ''}${trend.toStringAsFixed(1)}%',
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
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Chart
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.card,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Legend
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _LegendDot(color: holdingColor, label: 'Holdings'),
                                  const SizedBox(width: AppSpacing.lg),
                                  _LegendDot(color: liabilityColor, label: 'Liabilities'),
                                  const SizedBox(width: AppSpacing.lg),
                                  _LegendDot(color: netWorthColor, label: 'Net Worth'),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                height: 250,
                                child: _buildChart(snapshots, holdingColor, liabilityColor, netWorthColor, currencySymbol),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (snapshots.length < 3)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.mdAll,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.info, size: 16, color: AppColors.textTertiary),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'More history builds over time. A new data point is added each month.',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Monthly breakdown
                        const SizedBox(height: AppSpacing.lg),
                        Text('Monthly Breakdown', style: AppTypography.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        ...snapshots.reversed.map((s) {
                          final prevIndex = snapshots.indexOf(s) - 1;
                          final change = prevIndex >= 0
                              ? s.netWorth - snapshots[prevIndex].netWorth
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.smAll,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MMMM yyyy').format(s.date),
                                          style: AppTypography.bodyMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$currencySymbol${_formatNumber(s.netWorth)}',
                                          style: AppTypography.moneySmall.copyWith(
                                            color: s.netWorth >= 0 ? holdingColor : liabilityColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (change != null)
                                    Text(
                                      '${change >= 0 ? '+' : ''}$currencySymbol${_formatNumber(change)}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: change >= 0 ? AppColors.green : AppColors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    List snapshots,
    Color holdingColor,
    Color liabilityColor,
    Color netWorthColor,
    String currencySymbol,
  ) {
    final holdingSpots = snapshots.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value as dynamic).totalHoldings as double);
    }).toList();
    final liabilitySpots = snapshots.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value as dynamic).totalLiabilities as double);
    }).toList();
    final netWorthSpots = snapshots.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value as dynamic).netWorth as double);
    }).toList();

    final allValues = [
      ...holdingSpots.map((s) => s.y),
      ...liabilitySpots.map((s) => s.y),
      ...netWorthSpots.map((s) => s.y),
    ];
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.1 : 100.0;

    return LineChart(
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: snapshots.length <= 6 ? 1 : (snapshots.length / 6).roundToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= snapshots.length) return const SizedBox.shrink();
                final date = (snapshots[index] as dynamic).date as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    DateFormat('M/yy').format(date),
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
                  _formatAmountShort(value, currencySymbol),
                  style: AppTypography.labelSmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (snapshots.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: holdingSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: holdingColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: snapshots.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              color: holdingColor.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: liabilitySpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: liabilityColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: snapshots.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              color: liabilityColor.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: netWorthSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: netWorthColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: snapshots.length <= 12,
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
                if (index < 0 || index >= snapshots.length) return null;
                final s = snapshots[index] as dynamic;
                final date = s.date as DateTime;
                String label;
                if (spot.barIndex == 0) {
                  label = 'Holdings: $currencySymbol${_formatNumber(s.totalHoldings as double)}';
                } else if (spot.barIndex == 1) {
                  label = 'Liabilities: $currencySymbol${_formatNumber(s.totalLiabilities as double)}';
                } else {
                  label = 'Net Worth: $currencySymbol${_formatNumber(s.netWorth as double)}';
                }
                return LineTooltipItem(
                  '${DateFormat('MMM yyyy').format(date)}\n$label',
                  AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  static String _formatNumber(double value) {
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
      (m) => '${m[1]},',
    );
  }

  static String _formatAmountShort(double value, String symbol) {
    if (value.abs() >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(1)}K';
    }
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
