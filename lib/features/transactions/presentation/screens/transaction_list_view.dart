import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../../../../navigation/app_router.dart';
import '../providers/transaction_selection_provider.dart';
import '../providers/transactions_provider.dart';

/// Displays grouped transaction list with pull-to-refresh, swipe actions,
/// selection mode, staggered animation on initial load, and infinite scroll
/// pagination.
class TransactionListView extends ConsumerStatefulWidget {
  final List<TransactionGroup> groups;
  final bool isInitialLoad;
  final bool hasMore;
  final VoidCallback onRefresh;
  final VoidCallback? onLoadMore;

  const TransactionListView({
    super.key,
    required this.groups,
    required this.isInitialLoad,
    this.hasMore = false,
    required this.onRefresh,
    this.onLoadMore,
  });

  @override
  ConsumerState<TransactionListView> createState() =>
      _TransactionListViewState();
}

class _TransactionListViewState extends ConsumerState<TransactionListView> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || _loadingMore || widget.onLoadMore == null) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    // Trigger load more when within 200px of the bottom.
    if (currentScroll >= maxScroll - 200) {
      _loadingMore = true;
      widget.onLoadMore!();

      // Reset loading flag after the frame so the new data can arrive.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: EmptyState.centered(
            icon: LucideIcons.receipt,
            title: 'No transactions found',
            subtitle: 'Try adjusting your filters or add a new transaction',
          ),
        ),
      );
    }

    // Extra item at the end for the loading indicator when more data is available.
    final itemCount = widget.groups.length + (widget.hasMore ? 1 : 0);

    return RefreshIndicator(
      color: AppColors.textPrimary,
      backgroundColor: AppColors.surface,
      onRefresh: () async => widget.onRefresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          bottom: AppSpacing.bottomNavHeight + AppSpacing.lg,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index >= widget.groups.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: LoadingIndicator()),
            );
          }

          final child = _TransactionGroupWidget(group: widget.groups[index]);
          if (widget.isInitialLoad && index < 15) {
            return StaggeredListItem(
              index: index,
              child: child,
            );
          }
          return child;
        },
      ),
    );
  }
}

class _TransactionGroupWidget extends ConsumerWidget {
  final TransactionGroup group;

  const _TransactionGroupWidget({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);
    final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};
    final netAmount = group.netAmountInMainCurrency(rates, mainCurrency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormatter.formatGroupHeader(group.date),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.formatWithSign(
                  netAmount.abs(),
                  netAmount >= 0 ? 'income' : 'expense',
                  currencyCode: mainCurrency,
                ),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        ...group.transactions.map((tx) => _TransactionItem(transaction: tx)),
        const SizedBox(height: AppSpacing.md),
      ],
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
    final isSelectionMode = ref.watch(transactionSelectionModeProvider);
    final isSelected = ref.watch(isTransactionSelectedProvider(transaction.id));
    final accentColor = ref.watch(accentColorProvider);

    Widget itemContent = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isSelected ? accentColor.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Selection checkbox
          if (isSelectionMode) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? accentColor : AppColors.textTertiary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(LucideIcons.check, color: AppColors.background, size: 14)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isTransfer)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${account?.name ?? '?'} → ${destAccount?.name ?? '?'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (transaction.note != null && transaction.note!.isNotEmpty)
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
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Builder(builder: (context) {
                final mainCurrency = ref.watch(mainCurrencyCodeProvider);
                final isForeign = transaction.currencyCode != mainCurrency;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isTransfer
                          ? CurrencyFormatter.format(transaction.amount, currencyCode: transaction.currencyCode)
                          : CurrencyFormatter.formatWithSign(transaction.amount, transaction.type.name, currencyCode: transaction.currencyCode),
                      style: AppTypography.moneySmall.copyWith(color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isForeign) Builder(builder: (context) {
                      final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};
                      final converted = convertToMainCurrency(transaction.amount, transaction.currencyCode, mainCurrency, rates);
                      return Text(
                        '\u2248 ${CurrencyFormatter.format(converted, currencyCode: mainCurrency)}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    if (!isTransfer && !isForeign)
                      Text(
                        account?.name ?? 'Unknown',
                        style: AppTypography.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );

    // In selection mode: tap to toggle selection, long-press does nothing
    if (isSelectionMode) {
      return GestureDetector(
        onTap: () {
          final ids = ref.read(selectedTransactionIdsProvider);
          final updated = Set<String>.from(ids);
          if (updated.contains(transaction.id)) {
            updated.remove(transaction.id);
            // Exit selection mode if nothing selected
            if (updated.isEmpty) {
              ref.read(transactionSelectionModeProvider.notifier).state = false;
            }
          } else {
            updated.add(transaction.id);
          }
          ref.read(selectedTransactionIdsProvider.notifier).state = updated;
        },
        child: itemContent,
      );
    }

    // Normal mode: swipe-left to delete, swipe-right to duplicate, tap to edit, long-press to select
    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Duplicate transaction'): () {
          // Triggered by accessibility services
        },
        const CustomSemanticsAction(label: 'Delete transaction'): () {
          final tx = transaction;
          ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
          context.showUndoNotification(
            'Transaction deleted',
            () => ref.read(transactionsProvider.notifier).restoreTransaction(tx),
          );
        },
      },
      onLongPressHint: 'Select for bulk actions',
      child: Dismissible(
      key: ValueKey(transaction.id),
      background: Semantics(
        label: 'Swipe right to duplicate',
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.15),
            borderRadius: AppRadius.mdAll,
          ),
          alignment: Alignment.centerLeft,
          child: Icon(
            LucideIcons.copy,
            color: AppColors.cyan,
            size: 22,
          ),
        ),
      ),
      secondaryBackground: Semantics(
        label: 'Swipe left to delete',
        child: Container(
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
      ),
      confirmDismiss: (direction) async {
        final hapticEnabled = ref.read(hapticEnabledProvider);
        await HapticHelper.mediumImpact(enabled: hapticEnabled);
        if (direction == DismissDirection.startToEnd) {
          // Duplicate: create new transaction with same details, today's date
          final tx = transaction;
          final mainCurrency = ref.read(mainCurrencyCodeProvider);
          final rates = ref.read(exchangeRatesProvider).valueOrNull ?? {};
          // Recompute conversion rate using current live rates
          final newConversionRate = (tx.currencyCode != mainCurrency && rates[tx.currencyCode] != null)
              ? 1.0 / rates[tx.currencyCode]!
              : tx.conversionRate;
          final newMainCurrencyAmount = tx.currencyCode == mainCurrency
              ? tx.amount
              : roundCurrency(tx.amount * newConversionRate);
          await ref.read(transactionsProvider.notifier).addTransaction(
                amount: tx.amount,
                type: tx.type,
                categoryId: tx.categoryId,
                accountId: tx.accountId,
                destinationAccountId: tx.destinationAccountId,
                currencyCode: tx.currencyCode,
                conversionRate: newConversionRate,
                destinationAmount: tx.destinationAmount,
                mainCurrencyCode: mainCurrency,
                mainCurrencyAmount: newMainCurrencyAmount,
                date: DateTime.now(),
                note: tx.note,
                merchant: tx.merchant,
              );
          if (context.mounted) {
            context.showSuccessNotification('Transaction duplicated');
          }
          return false; // Don't dismiss, just duplicate
        }
        return true; // Allow delete dismissal
      },
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
        onLongPress: () {
          ref.read(transactionSelectionModeProvider.notifier).state = true;
          ref.read(selectedTransactionIdsProvider.notifier).state = {transaction.id};
        },
        child: itemContent,
      ),
    ),
    );
  }
}
