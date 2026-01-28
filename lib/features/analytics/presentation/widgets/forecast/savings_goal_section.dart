import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/savings_goal_provider.dart';

class SavingsGoalSection extends ConsumerStatefulWidget {
  const SavingsGoalSection({super.key});

  @override
  ConsumerState<SavingsGoalSection> createState() => _SavingsGoalSectionState();
}

class _SavingsGoalSectionState extends ConsumerState<SavingsGoalSection> {
  final _controller = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(savingsGoalProvider);
    final target = ref.watch(savingsGoalTargetProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final accentColor = ref.watch(accentColorProvider);

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
            Row(
              children: [
                Icon(LucideIcons.target, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text('Savings Goal', style: AppTypography.labelLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Target input
            if (_editing || target == 0)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter target amount',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                        prefixText: currencySymbol,
                        prefixStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.smAll,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.smAll,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.smAll,
                          borderSide: BorderSide(color: accentColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () {
                      final value = double.tryParse(_controller.text) ?? 0;
                      ref.read(savingsGoalTargetProvider.notifier).state = value;
                      setState(() => _editing = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smAll,
                        border: Border.all(color: accentColor),
                      ),
                      child: Icon(LucideIcons.check, size: 16, color: accentColor),
                    ),
                  ),
                ],
              )
            else ...[
              // Show goal progress
              GestureDetector(
                onTap: () {
                  _controller.text = target.toStringAsFixed(0);
                  setState(() => _editing = true);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: $currencySymbol${target.toStringAsFixed(0)}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    Icon(LucideIcons.pencil, size: 12, color: AppColors.textTertiary),
                  ],
                ),
              ),
              if (goal != null) ...[
                const SizedBox(height: AppSpacing.md),
                // Progress gauge
                SizedBox(
                  height: 80,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(200, 80),
                      painter: _GoalGaugePainter(
                        progress: goal.progressPercent / 100,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    '${goal.progressPercent.toStringAsFixed(1)}%',
                    style: AppTypography.moneySmall.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 9)),
                        Text('$currencySymbol${goal.currentSaved.toStringAsFixed(0)}', style: AppTypography.labelMedium),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Monthly', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 9)),
                        Text(
                          '$currencySymbol${goal.projectedMonthlySavings.toStringAsFixed(0)}',
                          style: AppTypography.labelMedium.copyWith(
                            color: goal.projectedMonthlySavings > 0 ? AppColors.green : AppColors.red,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Months', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 9)),
                        Text(
                          goal.monthsToGoal != null ? '${goal.monthsToGoal}' : '--',
                          style: AppTypography.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalGaugePainter extends CustomPainter {
  final double progress; // 0 to 1
  final Color color;

  _GoalGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    const startAngle = pi;
    const sweepAngle = pi;

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

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress.clamp(0, 1),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalGaugePainter old) =>
      old.progress != progress || old.color != color;
}
