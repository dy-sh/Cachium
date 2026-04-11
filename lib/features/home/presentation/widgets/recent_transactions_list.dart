import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/animations/shimmer_loading.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../navigation/app_router.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return transactionsAsync.when(
      loading: () => const ShimmerList(
        variant: ShimmerListVariant.transaction,
        count: 4,
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error loading transactions',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                GestureDetector(
                  onTap: () => ref.invalidate(recentTransactionsProvider),
                  child: Text(
                    'Try again',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: EmptyState.centered(
              icon: LucideIcons.receipt,
              title: 'No transactions yet',
              subtitle: 'Tap to add your first transaction',
              actionLabel: 'Add Transaction',
              onTap: () => context.push(AppRoutes.transactionForm),
            ),
          );
        }

        // Hoist lookups to parent — single watch per map instead of N watches per item
        final categoryMap = ref.watch(categoryMapProvider);
        final accountMap = ref.watch(accountMapProvider);
        final intensity = ref.watch(colorIntensityProvider);
        final mainCurrency = ref.watch(mainCurrencyCodeProvider);
        final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: transactions.map((tx) => _TransactionItem(
              transaction: tx,
              category: categoryMap[tx.categoryId],
              account: accountMap[tx.accountId],
              destAccount: tx.destinationAccountId != null ? accountMap[tx.destinationAccountId!] : null,
              intensity: intensity,
              mainCurrency: mainCurrency,
              rates: rates,
            )).toList(),
          ),
        );
      },
    );
  }
}

class _TransactionItem extends ConsumerWidget {
  final Transaction transaction;
  final Category? category;
  final Account? account;
  final Account? destAccount;
  final ColorIntensity intensity;
  final String mainCurrency;
  final Map<String, double> rates;

  const _TransactionItem({
    required this.transaction,
    required this.category,
    required this.account,
    required this.destAccount,
    required this.intensity,
    required this.mainCurrency,
    required this.rates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: const Icon(
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
        onTap: () => context.push(AppRoutes.transactionDetailPath(transaction.id)),
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
              SizedBox(
                width: 43,
                height: 43,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: bgOpacity),
                        borderRadius: AppRadius.iconButton,
                      ),
                      child: Icon(
                        isTransfer ? LucideIcons.arrowLeftRight : (category?.icon ?? Icons.circle),
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                    if (transaction.assetId != null)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Icon(
                            LucideIcons.box,
                            size: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
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
              Builder(builder: (context) {
                final isForeign = transaction.currencyCode != mainCurrency;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isTransfer
                          ? CurrencyFormatter.format(transaction.amount, currencyCode: transaction.currencyCode)
                          : CurrencyFormatter.formatWithSign(transaction.amount, transaction.type.name, currencyCode: transaction.currencyCode),
                      style: AppTypography.moneySmall.copyWith(color: color),
                    ),
                    if (isForeign) Builder(builder: (context) {
                      final converted = convertToMainCurrency(transaction.amount, transaction.currencyCode, mainCurrency, rates);
                      return Text(
                        '\u2248 ${CurrencyFormatter.format(converted, currencyCode: mainCurrency)}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
