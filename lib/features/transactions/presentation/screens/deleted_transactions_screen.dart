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
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transactions_provider.dart';

final _deletedSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final _filteredDeletedTransactionsProvider =
    Provider.autoDispose<AsyncValue<List<Transaction>>>((ref) {
  final deletedAsync = ref.watch(deletedTransactionsProvider);
  final query = ref.watch(_deletedSearchQueryProvider).toLowerCase().trim();

  return deletedAsync.whenData((transactions) {
    if (query.isEmpty) return transactions;

    return transactions.where((tx) {
      final amount = CurrencyFormatter.format(tx.amount).toLowerCase();
      final amountRaw = tx.amount.toString();
      final note = tx.note?.toLowerCase() ?? '';
      final merchant = tx.merchant?.toLowerCase() ?? '';
      final date = DateFormatter.formatRelative(tx.date).toLowerCase();

      return amount.contains(query) ||
          amountRaw.contains(query) ||
          note.contains(query) ||
          merchant.contains(query) ||
          date.contains(query);
    }).toList();
  });
});

class DeletedTransactionsScreen extends ConsumerWidget {
  const DeletedTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(_filteredDeletedTransactionsProvider);
    final totalCount = ref.watch(deletedTransactionsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Deleted Transactions',
              onClose: () => context.pop(),
              trailing: totalCount > 0
                  ? Text(
                      '$totalCount',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    )
                  : null,
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (value) {
                    ref.read(_deletedSearchQueryProvider.notifier).state = value;
                  },
                  style: AppTypography.bodyMedium,
                  cursorColor: AppColors.textPrimary,
                  decoration: InputDecoration(
                    hintText: 'Search by amount, note, merchant, date...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // List
            Expanded(
              child: filteredAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'Failed to load deleted transactions',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: EmptyState.centered(
                          icon: LucideIcons.trash2,
                          title: totalCount == 0
                              ? 'No deleted transactions'
                              : 'No matching transactions',
                          subtitle: totalCount == 0
                              ? 'Deleted transactions will appear here'
                              : 'Try a different search term',
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return _DeletedTransactionItem(
                        transaction: transactions[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedTransactionItem extends ConsumerWidget {
  final Transaction transaction;

  const _DeletedTransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final account = ref.watch(accountByIdProvider(transaction.accountId));
    final intensity = ref.watch(colorIntensityProvider);
    final isIncome = transaction.type == TransactionType.income;
    final color = AppColors.getTransactionColor(
      isIncome ? 'income' : 'expense',
      intensity,
    );
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor =
        category?.getColor(intensity) ?? AppColors.textSecondary;

    return Container(
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: bgOpacity),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.formatWithSign(
                        transaction.amount,
                        transaction.type.name,
                      ),
                      style: AppTypography.bodySmall.copyWith(color: color),
                    ),
                    Text(
                      ' · ${account?.name ?? 'Unknown'} · ${DateFormatter.formatRelative(transaction.date)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      transaction.note!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () async {
              final notifier = ref.read(transactionsProvider.notifier);
              await notifier.restoreTransaction(transaction);
              if (context.mounted) {
                context.showSuccessNotification('Transaction restored');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: AppRadius.smAll,
              ),
              child: Text(
                'Restore',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
