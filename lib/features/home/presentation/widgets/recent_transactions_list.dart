import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return transactionsAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => Padding(
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
              'Error loading transactions',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: GestureDetector(
              onTap: () => context.push('/transaction/new'),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.receipt,
                      size: 28,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No transactions yet',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap to add your first transaction',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
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
      },
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
    final destAccount = transaction.destinationAccountId != null
        ? ref.watch(accountByIdProvider(transaction.destinationAccountId!))
        : null;
    final intensity = ref.watch(colorIntensityProvider);
    final isTransfer = transaction.type == TransactionType.transfer;
    final color = AppColors.getTransactionColor(transaction.type.name, intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = isTransfer
        ? AppColors.getTransactionColor('transfer', intensity)
        : (category?.getColor(intensity) ?? AppColors.textSecondary);

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.15),
          borderRadius: AppRadius.mdAll,
        ),
        alignment: Alignment.centerRight,
        child: Icon(
          LucideIcons.trash2,
          color: AppColors.red,
          size: 22,
        ),
      ),
      onDismissed: (_) {
        final tx = transaction;
        ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
        context.showUndoNotification(
          'Transaction deleted',
          () => ref.read(transactionsProvider.notifier).restoreTransaction(tx),
        );
      },
      child: GestureDetector(
        onTap: () => context.push('/transaction/${transaction.id}'),
        child: Container(
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
                  color: categoryColor.withValues(alpha: bgOpacity),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isTransfer ? LucideIcons.arrowLeftRight : (category?.icon ?? Icons.circle),
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
                      isTransfer ? 'Transfer' : (category?.name ?? 'Unknown'),
                      style: AppTypography.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTransfer
                          ? '${account?.name ?? '?'} → ${destAccount?.name ?? '?'} • ${DateFormatter.formatRelative(transaction.date)}'
                          : '${account?.name ?? 'Unknown'} • ${DateFormatter.formatRelative(transaction.date)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isTransfer
                    ? CurrencyFormatter.format(transaction.amount)
                    : CurrencyFormatter.formatWithSign(transaction.amount, transaction.type.name),
                style: AppTypography.moneySmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
