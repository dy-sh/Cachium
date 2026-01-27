import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../navigation/app_router.dart';
import '../../../../budgets/data/models/budget_progress.dart';
import '../../../../settings/data/models/app_settings.dart';
import '../../../../budgets/presentation/providers/budget_provider.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';

class BudgetProgressSection extends ConsumerWidget {
  const BudgetProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final progressList = ref.watch(
      budgetProgressProvider((year: now.year, month: now.month)),
    );
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final accentColor = ref.watch(accentColorProvider);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget Progress', style: AppTypography.h4),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.budgetSettings),
                  child: Text(
                    'Manage',
                    style: AppTypography.labelLarge.copyWith(
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (progressList.isEmpty)
              _EmptyState(accentColor: accentColor)
            else
              ...progressList.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _BudgetBar(
                      progress: p,
                      currencySymbol: currencySymbol,
                      colorIntensity: colorIntensity,
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accentColor;
  const _EmptyState({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(LucideIcons.target, size: 32, color: AppColors.textTertiary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No budgets set',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => context.push(AppRoutes.budgetSettings),
          child: Text(
            'Set up budgets',
            style: AppTypography.labelLarge.copyWith(color: accentColor),
          ),
        ),
      ],
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final BudgetProgress progress;
  final String currencySymbol;
  final ColorIntensity colorIntensity;

  const _BudgetBar({
    required this.progress,
    required this.currencySymbol,
    required this.colorIntensity,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = progress.percentage < 75
        ? AppColors.getTransactionColor('income', colorIntensity)
        : progress.percentage <= 100
            ? AppColors.yellow
            : AppColors.getTransactionColor('expense', colorIntensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(progress.categoryIcon,
                size: 14, color: progress.categoryColor),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                progress.categoryName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${progress.percentage.toStringAsFixed(0)}%',
              style: AppTypography.labelSmall.copyWith(
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.fullAll,
          child: LinearProgressIndicator(
            value: (progress.percentage / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            color: barColor,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
