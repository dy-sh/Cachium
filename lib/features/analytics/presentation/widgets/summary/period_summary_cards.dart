import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/income_expense_summary_provider.dart';

class PeriodSummaryCards extends ConsumerWidget {
  const PeriodSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(incomeExpenseSummaryProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    final incomeColor = AppColors.getTransactionColor('income', colorIntensity);
    final expenseColor = AppColors.getTransactionColor('expense', colorIntensity);
    final netColor = summary.netAmount >= 0 ? incomeColor : expenseColor;

    final hasPreviousData = summary.previousTotalIncome > 0 || summary.previousTotalExpense > 0;

    return SizedBox(
      height: hasPreviousData ? 108 : 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        children: [
          _SummaryCard(
            title: 'Income',
            value: summary.totalIncome,
            icon: LucideIcons.trendingUp,
            color: incomeColor,
            currencySymbol: currencySymbol,
            changePercent: hasPreviousData ? summary.incomeChangePercent : null,
            changeIsGood: true, // income increase is good
          ),
          const SizedBox(width: AppSpacing.sm),
          _SummaryCard(
            title: 'Expenses',
            value: summary.totalExpense,
            icon: LucideIcons.trendingDown,
            color: expenseColor,
            currencySymbol: currencySymbol,
            changePercent: hasPreviousData ? summary.expenseChangePercent : null,
            changeIsGood: false, // expense increase is bad
          ),
          const SizedBox(width: AppSpacing.sm),
          _SummaryCard(
            title: 'Net',
            value: summary.netAmount,
            icon: LucideIcons.equal,
            color: netColor,
            currencySymbol: currencySymbol,
            showSign: true,
            changePercent: hasPreviousData ? summary.netChangePercent : null,
            changeIsGood: true, // net increase is good
          ),
          const SizedBox(width: AppSpacing.sm),
          _SummaryCard(
            title: 'Avg/Day',
            value: summary.averageDailyExpense,
            icon: LucideIcons.calendar,
            color: AppColors.textSecondary,
            currencySymbol: currencySymbol,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String currencySymbol;
  final bool showSign;
  final double? changePercent;
  final bool changeIsGood;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.currencySymbol,
    this.showSign = false,
    this.changePercent,
    this.changeIsGood = true,
  });

  @override
  Widget build(BuildContext context) {
    String displayValue;
    if (value.abs() >= 1000000) {
      displayValue = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 10000) {
      displayValue = '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      displayValue = value.toStringAsFixed(2);
    }

    final prefix = showSign && value > 0 ? '+' : '';

    return Container(
      width: 110,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            '$prefix$currencySymbol$displayValue',
            style: AppTypography.moneySmall.copyWith(
              color: showSign ? color : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (changePercent != null) _buildChangeRow(),
        ],
      ),
    );
  }

  Widget _buildChangeRow() {
    final pct = changePercent!;
    final isUp = pct > 0;
    // For income/net: up=green, down=red. For expenses: up=red, down=green.
    final isGood = changeIsGood ? isUp : !isUp;
    final changeColor = pct == 0
        ? AppColors.textTertiary
        : (isGood ? AppColors.green : AppColors.red);

    return Row(
      children: [
        if (pct != 0)
          Icon(
            isUp ? LucideIcons.arrowUp : LucideIcons.arrowDown,
            size: 10,
            color: changeColor,
          ),
        const SizedBox(width: 2),
        Text(
          '${isUp ? '+' : ''}${pct.toStringAsFixed(0)}%',
          style: AppTypography.labelSmall.copyWith(
            color: changeColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
