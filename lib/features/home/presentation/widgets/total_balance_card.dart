import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/animations/animated_counter.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

class TotalBalanceCard extends ConsumerWidget {
  const TotalBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = ref.watch(totalBalanceProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedCounter(
            value: totalBalance,
            style: AppTypography.moneyLarge.copyWith(
              fontSize: 26,
              color: AppColors.textPrimary.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _BalanceIndicator(
                label: 'Assets',
                value: _getAssets(ref),
                color: AppColors.income,
              ),
              const SizedBox(width: AppSpacing.lg),
              _BalanceIndicator(
                label: 'Liabilities',
                value: _getLiabilities(ref),
                color: AppColors.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getAssets(WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    return accounts
        .where((a) => a.balance > 0)
        .fold(0.0, (sum, a) => sum + a.balance);
  }

  double _getLiabilities(WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    return accounts
        .where((a) => a.balance < 0)
        .fold(0.0, (sum, a) => sum + a.balance.abs());
  }
}

class _BalanceIndicator extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _BalanceIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall,
            ),
            AnimatedCounter(
              value: value,
              style: AppTypography.moneyTiny.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }
}
