import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/financial_health_provider.dart';

class FinancialHealthSection extends ConsumerWidget {
  const FinancialHealthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(financialHealthProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);

    if (health.healthScore == 0 &&
        health.debtToAssetRatio == 0 &&
        health.savingsRate == 0 &&
        health.emergencyFundMonths == 0) {
      return const SizedBox.shrink();
    }

    final scoreColor = _getScoreColor(health.healthScore, colorIntensity);

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
            Text('Financial Health Score', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.lg),
            // Score gauge
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _ScoreGaugePainter(
                      score: health.healthScore,
                      color: scoreColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${health.healthScore}',
                            style: AppTypography.moneyMedium.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                            ),
                          ),
                          Text(
                            _getScoreLabel(health.healthScore),
                            style: AppTypography.labelSmall.copyWith(
                              color: scoreColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    children: [
                      _MetricRow(
                        icon: LucideIcons.scale,
                        label: 'Debt Ratio',
                        value: '${health.debtToAssetRatio.toStringAsFixed(1)}%',
                        isGood: health.debtToAssetRatio < 50,
                        colorIntensity: colorIntensity,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricRow(
                        icon: LucideIcons.piggyBank,
                        label: 'Savings Rate',
                        value: '${health.savingsRate.toStringAsFixed(1)}%',
                        isGood: health.savingsRate > 0,
                        colorIntensity: colorIntensity,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricRow(
                        icon: LucideIcons.shield,
                        label: 'Emergency Fund',
                        value: '${health.emergencyFundMonths.toStringAsFixed(1)} mo',
                        isGood: health.emergencyFundMonths >= 3,
                        colorIntensity: colorIntensity,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricRow(
                        icon: LucideIcons.trendingUp,
                        label: 'Net Worth Trend',
                        value: '${health.netWorthTrend >= 0 ? '+' : ''}${health.netWorthTrend.toStringAsFixed(1)}%',
                        isGood: health.netWorthTrend >= 0,
                        colorIntensity: colorIntensity,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score, colorIntensity) {
    if (score >= 80) {
      return AppColors.getTransactionColor('income', colorIntensity);
    } else if (score >= 50) {
      return AppColors.yellow;
    } else {
      return AppColors.getTransactionColor('expense', colorIntensity);
    }
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }
}

class _ScoreGaugePainter extends CustomPainter {
  final int score;
  final Color color;

  _ScoreGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final scoreSweep = sweepAngle * (score / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      scoreSweep,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isGood;
  final dynamic colorIntensity;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isGood,
    required this.colorIntensity,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isGood
        ? AppColors.getTransactionColor('income', colorIntensity)
        : AppColors.getTransactionColor('expense', colorIntensity);

    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
