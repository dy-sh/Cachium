import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/income_expense_summary_provider.dart';

class SavingsGauge extends ConsumerStatefulWidget {
  const SavingsGauge({super.key});

  @override
  ConsumerState<SavingsGauge> createState() => _SavingsGaugeState();
}

class _SavingsGaugeState extends ConsumerState<SavingsGauge> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final summary = ref.watch(incomeExpenseSummaryProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final accentColor = ref.watch(accentColorProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (summary.totalIncome == 0 && summary.totalExpense == 0) {
      return const SizedBox.shrink();
    }

    final savingsRate = summary.savingsRate.clamp(-100.0, 100.0);
    final expenseRatio = summary.totalIncome > 0
        ? (summary.totalExpense / summary.totalIncome * 100).clamp(0.0, 100.0)
        : 0.0;
    final incomeChange = summary.incomeChangePercent.clamp(-100.0, 100.0);

    final incomeColor = AppColors.getTransactionColor('income', colorIntensity);
    final expenseColor = AppColors.getTransactionColor('expense', colorIntensity);

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
          Text('Financial Health', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onLongPress: () => setState(() => _showDetails = !_showDetails),
            child: SizedBox(
              height: 160,
              child: Center(
                child: CustomPaint(
                  size: const Size(160, 160),
                  painter: _GaugePainter(
                  rings: [
                    _GaugeRing(
                      label: 'Savings',
                      value: savingsRate / 100,
                      color: savingsRate >= 0 ? incomeColor : expenseColor,
                    ),
                    _GaugeRing(
                      label: 'Budget',
                      value: expenseRatio / 100,
                      color: expenseRatio < 80 ? accentColor : expenseColor,
                    ),
                    _GaugeRing(
                      label: 'Income',
                      value: (incomeChange / 100).clamp(-1.0, 1.0),
                      color: incomeChange >= 0 ? incomeColor : expenseColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppRadius.smAll,
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Income', value: summary.totalIncome, color: incomeColor, currencySymbol: currencySymbol),
                    _DetailRow(label: 'Expenses', value: summary.totalExpense, color: expenseColor, currencySymbol: currencySymbol),
                    _DetailRow(label: 'Net', value: summary.netAmount, color: summary.netAmount >= 0 ? incomeColor : expenseColor, currencySymbol: currencySymbol),
                  ],
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _GaugeLabel(
                label: 'Savings Rate',
                value: '${savingsRate.toStringAsFixed(0)}%',
                color: savingsRate >= 0 ? incomeColor : expenseColor,
              ),
              _GaugeLabel(
                label: 'Budget Used',
                value: '${expenseRatio.toStringAsFixed(0)}%',
                color: expenseRatio < 80 ? accentColor : expenseColor,
              ),
              _GaugeLabel(
                label: 'Income Δ',
                value: '${incomeChange >= 0 ? '+' : ''}${incomeChange.toStringAsFixed(0)}%',
                color: incomeChange >= 0 ? incomeColor : expenseColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugeRing {
  final String label;
  final double value; // -1 to 1
  final Color color;
  const _GaugeRing({required this.label, required this.value, required this.color});
}

class _GaugePainter extends CustomPainter {
  final List<_GaugeRing> rings;

  _GaugePainter({required this.rings});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    for (int i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final radius = (size.width / 2) - (i * 22) - 5;
      if (radius < 10) break;

      // Background arc
      final bgPaint = Paint()
        ..color = AppColors.border.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        bgPaint,
      );

      // Value arc
      final valuePaint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      final valueSweep = sweepAngle * ring.value.abs().clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        valueSweep,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return true;
  }
}

class _GaugeLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _GaugeLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.labelLarge.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 9)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String currencySymbol;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
          Text(
            '$currencySymbol${value.toStringAsFixed(2)}',
            style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
