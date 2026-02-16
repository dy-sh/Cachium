import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/account.dart';
import '../providers/accounts_provider.dart';

class AccountDetailScreen extends ConsumerWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountByIdProvider(accountId));
    final intensity = ref.watch(colorIntensityProvider);

    if (account == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              FormHeader(
                title: 'Account',
                onClose: () => context.pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text('Account not found'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final accountColor = account.getColorWithIntensity(intensity);
    final transactions = ref.watch(transactionsByAccountProvider(accountId));
    final bgOpacity = AppColors.getBgOpacity(intensity);

    // Calculate this month's income and expense for this account
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTransactions = transactions.where((tx) =>
        tx.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
        tx.accountId == accountId); // Only count when this is the source
    double monthIncome = 0;
    double monthExpense = 0;
    for (final tx in monthTransactions) {
      if (tx.type == TransactionType.income) {
        monthIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        monthExpense += tx.amount;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: account.name,
              onClose: () => context.pop(),
              trailing: PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.moreVertical,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                color: AppColors.surface,
                onSelected: (value) async {
                  if (value == 'edit') {
                    context.push('/account/${account.id}/edit');
                  } else if (value == 'duplicate') {
                    await ref.read(accountsProvider.notifier).addAccount(
                          name: '${account.name} (Copy)',
                          type: account.type,
                          initialBalance: account.initialBalance,
                          customColor: account.customColor,
                        );
                    if (context.mounted) {
                      context.showSuccessNotification('Account duplicated');
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(LucideIcons.pencil, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Edit', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(LucideIcons.copy, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Duplicate', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                children: [
                  // Account balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: accountColor.withValues(alpha: 0.3)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accountColor.withValues(alpha: bgOpacity * 0.5),
                          accountColor.withValues(alpha: bgOpacity * 0.2),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accountColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            account.icon,
                            color: AppColors.background,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          account.type.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(
                              text: CurrencyFormatter.format(account.balance),
                            ));
                            context.showSuccessNotification('Balance copied');
                          },
                          child: AnimatedCounter(
                            value: account.balance,
                            style: AppTypography.moneyLarge.copyWith(
                              fontSize: 32,
                              color: account.balance >= 0
                                  ? AppColors.textPrimary
                                  : AppColors.getTransactionColor('expense', intensity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Monthly stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Income',
                          amount: monthIncome,
                          color: AppColors.getTransactionColor('income', intensity),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          label: 'Expense',
                          amount: monthExpense,
                          color: AppColors.getTransactionColor('expense', intensity),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Transaction history
                  Text('Transaction History', style: AppTypography.h4),
                  const SizedBox(height: AppSpacing.md),

                  if (transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mdAll,
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
                    )
                  else
                    ...transactions.map((tx) => _AccountTransactionItem(
                          transaction: tx,
                          accountId: accountId,
                        )),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTypography.moneySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _AccountTransactionItem extends ConsumerWidget {
  final Transaction transaction;
  final String accountId;

  const _AccountTransactionItem({
    required this.transaction,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final destAccount = transaction.destinationAccountId != null
        ? ref.watch(accountByIdProvider(transaction.destinationAccountId!))
        : null;
    final sourceAccount = ref.watch(accountByIdProvider(transaction.accountId));
    final intensity = ref.watch(colorIntensityProvider);
    final isTransfer = transaction.isTransfer;
    final color = AppColors.getTransactionColor(transaction.type.name, intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = isTransfer
        ? AppColors.getTransactionColor('transfer', intensity)
        : (category?.getColor(intensity) ?? AppColors.textSecondary);

    // For transfers, show direction relative to this account
    String subtitle;
    if (isTransfer) {
      if (transaction.accountId == accountId) {
        subtitle = 'To ${destAccount?.name ?? '?'}';
      } else {
        subtitle = 'From ${sourceAccount?.name ?? '?'}';
      }
    } else {
      subtitle = DateFormatter.formatRelative(transaction.date);
    }

    return GestureDetector(
      onTap: () => context.push('/transaction/${transaction.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: bgOpacity),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isTransfer ? LucideIcons.arrowLeftRight : (category?.icon ?? Icons.circle),
                color: categoryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTransfer ? 'Transfer' : (category?.name ?? 'Unknown'),
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTransfer
                        ? '$subtitle • ${DateFormatter.formatRelative(transaction.date)}'
                        : subtitle,
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
    );
  }
}
