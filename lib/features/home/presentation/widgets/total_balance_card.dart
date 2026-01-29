import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/animations/animated_counter.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class TotalBalanceCard extends ConsumerStatefulWidget {
  const TotalBalanceCard({super.key});

  @override
  ConsumerState<TotalBalanceCard> createState() => _TotalBalanceCardState();
}

class _TotalBalanceCardState extends ConsumerState<TotalBalanceCard> {
  bool _balanceRevealed = false;

  @override
  Widget build(BuildContext context) {
    final totalBalance = ref.watch(totalBalanceProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final incomeColor = AppColors.getTransactionColor('income', intensity);
    final expenseColor = AppColors.getTransactionColor('expense', intensity);
    final assets = _getAssets(ref);
    final liabilities = _getLiabilities(ref);
    final textSize = ref.watch(homeTotalBalanceTextSizeProvider);
    final balancesHidden = ref.watch(homeBalancesHiddenByDefaultProvider);
    final isSmall = textSize == AmountDisplaySize.small;

    // If balances are hidden by default, use local state to track reveal
    final showBalance = !balancesHidden || _balanceRevealed;

    // Typography based on size
    final mainBalanceStyle = isSmall
        ? AppTypography.moneyMedium.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            letterSpacing: -0.3,
          )
        : AppTypography.moneyLarge.copyWith(
            fontSize: 38,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          );

    return GestureDetector(
      onTap: balancesHidden && !_balanceRevealed
          ? () => setState(() => _balanceRevealed = true)
          : null,
      child: Container(
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
              AppColors.surfaceLight.withValues(alpha: 0.5),
              AppColors.surface.withValues(alpha: 0.3),
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
                        color: (totalBalance >= 0 ? incomeColor : expenseColor).withValues(alpha: 0.5),
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
            if (showBalance)
              AnimatedCounter(
                value: totalBalance,
                style: mainBalanceStyle,
              )
            else
              Text(
                '\u2022\u2022\u2022\u2022\u2022\u2022',
                style: mainBalanceStyle,
              ),
            const SizedBox(height: AppSpacing.xl),

            // Assets and Liabilities breakdown
            _BalanceBreakdown(
              assets: assets,
              liabilities: liabilities,
              incomeColor: incomeColor,
              expenseColor: expenseColor,
              isSmall: isSmall,
              showBalance: showBalance,
            ),
          ],
        ),
      ),
    );
  }

  double _getAssets(WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrEmpty;
    return accounts
        .where((a) => a.type.isAsset)
        .fold(0.0, (sum, a) => sum + a.balance);
  }

  double _getLiabilities(WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrEmpty;
    return accounts
        .where((a) => a.type.isLiability)
        .fold(0.0, (sum, a) => sum + a.balance.abs());
  }
}

class _BalanceBreakdown extends StatelessWidget {
  final double assets;
  final double liabilities;
  final Color incomeColor;
  final Color expenseColor;
  final bool isSmall;
  final bool showBalance;

  const _BalanceBreakdown({
    required this.assets,
    required this.liabilities,
    required this.incomeColor,
    required this.expenseColor,
    required this.isSmall,
    required this.showBalance,
  });

  @override
  Widget build(BuildContext context) {

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
                isSmall: isSmall,
                showBalance: showBalance,
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
                isSmall: isSmall,
                showBalance: showBalance,
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
  final bool isSmall;
  final bool showBalance;

  const _BalanceItem({
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
    required this.isSmall,
    required this.showBalance,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = isSmall
        ? AppTypography.moneyTiny.copyWith(
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          )
        : AppTypography.moneySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          );

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
                    color: color.withValues(alpha: 0.8),
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
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (showBalance)
            AnimatedCounter(
              value: value,
              style: valueStyle,
            )
          else
            Text(
              '\u2022\u2022\u2022\u2022',
              style: valueStyle,
            ),
        ],
      ),
    );
  }
}
