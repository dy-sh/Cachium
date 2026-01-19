import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider);

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Text(
              'No transactions yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: transactions.map((tx) => _TransactionItem(transaction: tx)).toList(),
      ),
    );
  }
}

class _TransactionItem extends ConsumerWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final account = ref.watch(accountByIdProvider(transaction.accountId));
    final intensity = ref.watch(colorIntensityProvider);
    final isIncome = transaction.type == TransactionType.income;
    final color = AppColors.getTransactionColor(isIncome ? 'income' : 'expense', intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = category?.getColor(intensity) ?? AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(bgOpacity),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category?.icon ?? Icons.circle,
              color: categoryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? 'Unknown',
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '${account?.name ?? 'Unknown'} • ${DateFormatter.formatRelative(transaction.date)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatWithSign(transaction.amount, transaction.type.name),
            style: AppTypography.moneySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
