import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/animations/animated_counter.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class TotalBalanceCard extends ConsumerWidget {
  const TotalBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = ref.watch(totalBalanceProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final incomeColor = AppColors.getTransactionColor('income', intensity);
    final expenseColor = AppColors.getTransactionColor('expense', intensity);
    final assets = _getAssets(ref);
    final liabilities = _getLiabilities(ref);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceLight.withOpacity(0.5),
            AppColors.surface.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: totalBalance >= 0 ? incomeColor : expenseColor,
                  boxShadow: [
                    BoxShadow(
                      color: (totalBalance >= 0 ? incomeColor : expenseColor).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'TOTAL BALANCE',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Main balance amount
          AnimatedCounter(
            value: totalBalance,
            style: AppTypography.moneyLarge.copyWith(
              fontSize: 38,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Assets and Liabilities breakdown
          _BalanceBreakdown(
            assets: assets,
            liabilities: liabilities,
            incomeColor: incomeColor,
            expenseColor: expenseColor,
          ),
        ],
      ),
    );
  }

  double _getAssets(WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    return accounts
        .where((a) => a.balance > 0)
        .fold(0.0, (sum, a) => sum + a.balance);
  }

  double _getLiabilities(WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    return accounts
        .where((a) => a.balance < 0)
        .fold(0.0, (sum, a) => sum + a.balance.abs());
  }
}

class _BalanceBreakdown extends StatelessWidget {
  final double assets;
  final double liabilities;
  final Color incomeColor;
  final Color expenseColor;

  const _BalanceBreakdown({
    required this.assets,
    required this.liabilities,
    required this.incomeColor,
    required this.expenseColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = assets + liabilities;
    final assetsRatio = total > 0 ? assets / total : 0.5;

    return Column(
      children: [
        // Labels with values
        Row(
          children: [
            Expanded(
              child: _BalanceItem(
                label: 'Assets',
                value: assets,
                color: incomeColor,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: AppColors.border,
            ),
            Expanded(
              child: _BalanceItem(
                label: 'Liabilities',
                value: liabilities,
                color: expenseColor,
                alignRight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool alignRight;

  const _BalanceItem({
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? AppSpacing.md : 0,
        right: alignRight ? 0 : AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!alignRight) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.8),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              if (alignRight) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: value,
            style: AppTypography.moneySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
