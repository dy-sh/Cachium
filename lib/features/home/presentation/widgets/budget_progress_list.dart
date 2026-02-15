import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../budgets/data/models/budget_progress.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class BudgetProgressList extends ConsumerWidget {
  const BudgetProgressList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final progressList = ref.watch(
      budgetProgressProvider((year: now.year, month: now.month)),
    );

    if (progressList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: progressList
            .take(3) // Show top 3 budgets on home screen
            .map((progress) => _BudgetProgressItem(progress: progress))
            .toList(),
      ),
    );
  }
}

class _BudgetProgressItem extends ConsumerWidget {
  final BudgetProgress progress;

  const _BudgetProgressItem({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final percentage = progress.percentage.clamp(0, 999).toDouble();
    final barProgress = (percentage / 100).clamp(0.0, 1.0);

    // Color coding: green (<75%), yellow (75-100%), red (>100%)
    final Color progressColor;
    if (percentage > 100) {
      progressColor = AppColors.getTransactionColor('expense', intensity);
    } else if (percentage >= 75) {
      progressColor = AppColors.yellow;
    } else {
      progressColor = AppColors.getTransactionColor('income', intensity);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: progress.categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  progress.categoryIcon,
                  color: progress.categoryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  progress.categoryName,
                  style: AppTypography.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${CurrencyFormatter.formatSimple(progress.spent)} / ${CurrencyFormatter.formatSimple(progress.budget.amount)}',
                style: AppTypography.bodySmall.copyWith(
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: barProgress,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
