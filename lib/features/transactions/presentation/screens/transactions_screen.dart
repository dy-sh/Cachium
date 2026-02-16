import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_selection_provider.dart';
import '../providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isInitialLoad = false);
      }
    });
  }

  void _exitSelectionMode() {
    ref.read(transactionSelectionModeProvider.notifier).state = false;
    ref.read(selectedTransactionIdsProvider.notifier).state = {};
  }

  void _selectAll() {
    final groups = ref.read(searchedTransactionsProvider).valueOrNull;
    if (groups == null) return;
    final allIds = groups.expand((g) => g.transactions).map((t) => t.id).toSet();
    ref.read(selectedTransactionIdsProvider.notifier).state = allIds;
  }

  Future<void> _deleteSelected() async {
    final selectedIds = ref.read(selectedTransactionIdsProvider);
    if (selectedIds.isEmpty) return;

    // Capture transactions before deletion for undo
    final allTransactions = ref.read(transactionsProvider).valueOrNull ?? [];
    final selectedTransactions =
        allTransactions.where((t) => selectedIds.contains(t.id)).toList();

    final count = selectedIds.length;

    await ref.read(transactionsProvider.notifier).deleteTransactions(selectedIds.toList());
    _exitSelectionMode();

    if (mounted) {
      context.showUndoNotification(
        '$count transaction${count == 1 ? '' : 's'} deleted',
        () => ref.read(transactionsProvider.notifier).restoreTransactions(selectedTransactions),
      );
    }
  }

  Future<void> _changeCategoryForSelected() async {
    final selectedIds = ref.read(selectedTransactionIdsProvider);
    if (selectedIds.isEmpty) return;

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final intensity = ref.read(colorIntensityProvider);

    final selectedCategoryId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _BulkPickerSheet(
        title: 'Change Category',
        items: categories
            .where((c) => c.parentId == null || true) // all categories
            .map((c) => _PickerItem(
                  id: c.id,
                  name: c.name,
                  icon: c.icon,
                  color: c.getColor(intensity),
                ))
            .toList(),
      ),
    );

    if (selectedCategoryId == null || !mounted) return;

    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);
    final allTransactions = ref.read(transactionsProvider).valueOrNull ?? [];
    final toUpdate = allTransactions.where((t) => selectedIds.contains(t.id)).toList();

    await db.transaction(() async {
      for (final tx in toUpdate) {
        final updated = tx.copyWith(categoryId: selectedCategoryId);
        await repo.updateTransaction(updated);
      }
    });

    await ref.read(transactionsProvider.notifier).refresh();
    _exitSelectionMode();

    if (mounted) {
      context.showSuccessNotification(
        '${toUpdate.length} transaction${toUpdate.length == 1 ? '' : 's'} updated',
      );
    }
  }

  Future<void> _changeAccountForSelected() async {
    final selectedIds = ref.read(selectedTransactionIdsProvider);
    if (selectedIds.isEmpty) return;

    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final intensity = ref.read(colorIntensityProvider);

    final selectedAccountId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _BulkPickerSheet(
        title: 'Change Account',
        items: accounts
            .map((a) => _PickerItem(
                  id: a.id,
                  name: a.name,
                  icon: a.icon,
                  color: a.getColorWithIntensity(intensity),
                ))
            .toList(),
      ),
    );

    if (selectedAccountId == null || !mounted) return;

    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);
    final allTransactions = ref.read(transactionsProvider).valueOrNull ?? [];
    final toUpdate = allTransactions.where((t) => selectedIds.contains(t.id)).toList();

    // Calculate balance adjustments
    await db.transaction(() async {
      for (final tx in toUpdate) {
        if (tx.accountId == selectedAccountId) continue;

        // Reverse old account balance
        if (tx.type == TransactionType.transfer) {
          await ref.read(accountsProvider.notifier).updateBalance(tx.accountId, tx.amount);
          await ref.read(accountsProvider.notifier).updateBalance(selectedAccountId, -tx.amount);
        } else {
          final reverseChange = tx.type == TransactionType.income ? -tx.amount : tx.amount;
          await ref.read(accountsProvider.notifier).updateBalance(tx.accountId, reverseChange);
          final applyChange = tx.type == TransactionType.income ? tx.amount : -tx.amount;
          await ref.read(accountsProvider.notifier).updateBalance(selectedAccountId, applyChange);
        }

        final updated = tx.copyWith(accountId: selectedAccountId);
        await repo.updateTransaction(updated);
      }
    });

    await ref.read(transactionsProvider.notifier).refresh();
    _exitSelectionMode();

    if (mounted) {
      context.showSuccessNotification(
        '${toUpdate.length} transaction${toUpdate.length == 1 ? '' : 's'} updated',
      );
    }
  }

  void _showMoreMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(button.size.width, 0), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      items: [
        PopupMenuItem(
          value: 'deleted',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Text('Deleted Transactions', style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'deleted' && mounted && context.mounted) {
        context.push(AppRoutes.deletedTransactions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(searchedTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final isSelectionMode = ref.watch(transactionSelectionModeProvider);
    final selectedCount = ref.watch(selectedCountProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          if (isSelectionMode)
            _SelectionHeader(
              selectedCount: selectedCount,
              onCancel: _exitSelectionMode,
              onSelectAll: _selectAll,
              onDelete: _deleteSelected,
              onChangeCategory: _changeCategoryForSelected,
              onChangeAccount: _changeAccountForSelected,
            )
          else
            _TransactionsHeader(
              onAdd: () => context.push(AppRoutes.transactionForm),
              onMore: () => _showMoreMenu(context),
            ),
          const SizedBox(height: AppSpacing.lg),

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
                  ref.read(transactionSearchQueryProvider.notifier).state = value;
                },
                style: AppTypography.bodyMedium,
                cursorColor: AppColors.textPrimary,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
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
          const SizedBox(height: AppSpacing.md),

          // Filter toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Builder(
              builder: (context) {
                final intensity = ref.watch(colorIntensityProvider);
                return ToggleChip(
                  options: const ['All', 'Income', 'Expense', 'Transfer'],
                  selectedIndex: filter.index,
                  colors: [
                    AppColors.textPrimary,
                    AppColors.getTransactionColor('income', intensity),
                    AppColors.getTransactionColor('expense', intensity),
                    AppColors.getTransactionColor('transfer', intensity),
                  ],
                  onChanged: (index) {
                    ref.read(transactionFilterProvider.notifier).state =
                        TransactionFilter.values[index];
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Transaction list
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(
                child: LoadingIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      color: AppColors.textTertiary,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Error loading transactions',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              data: (groups) => groups.isEmpty
                  ? Center(
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
                    )
                  : RefreshIndicator(
                      color: AppColors.textPrimary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        await ref.read(transactionsProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          left: AppSpacing.screenPadding,
                          right: AppSpacing.screenPadding,
                          bottom: AppSpacing.bottomNavHeight + AppSpacing.lg,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final child = _TransactionGroupWidget(group: groups[index]);
                          if (_isInitialLoad) {
                            return StaggeredListItem(
                              index: index,
                              child: child,
                            );
                          }
                          return child;
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsHeader extends ConsumerWidget {
  final VoidCallback onAdd;
  final VoidCallback onMore;

  const _TransactionsHeader({
    required this.onAdd,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Transactions', style: AppTypography.h2),
          Row(
            children: [
              GestureDetector(
                onTap: onMore,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    LucideIcons.moreHorizontal,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onChangeCategory;
  final VoidCallback onChangeAccount;

  const _SelectionHeader({
    required this.selectedCount,
    required this.onCancel,
    required this.onSelectAll,
    required this.onDelete,
    required this.onChangeCategory,
    required this.onChangeAccount,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                LucideIcons.x,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$selectedCount selected',
              style: AppTypography.h2,
            ),
          ),
          GestureDetector(
            onTap: hasSelection ? onChangeCategory : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.tag,
                color: hasSelection ? AppColors.textPrimary : AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: hasSelection ? onChangeAccount : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.wallet,
                color: hasSelection ? AppColors.textPrimary : AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onSelectAll,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                LucideIcons.checkSquare,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: hasSelection ? onDelete : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasSelection
                    ? AppColors.red.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasSelection
                      ? AppColors.red.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                LucideIcons.trash2,
                color: hasSelection ? AppColors.red : AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionGroupWidget extends ConsumerWidget {
  final TransactionGroup group;

  const _TransactionGroupWidget({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
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
              Row(
                children: [
                  if (group.totalIncome > 0) ...[
                    Text(
                      '+${CurrencyFormatter.format(group.totalIncome)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.getTransactionColor('income', intensity),
                        fontSize: 11,
                      ),
                    ),
                    if (group.totalExpense > 0)
                      const SizedBox(width: AppSpacing.xs),
                  ],
                  if (group.totalExpense > 0)
                    Text(
                      '-${CurrencyFormatter.format(group.totalExpense)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.getTransactionColor('expense', intensity),
                        fontSize: 11,
                      ),
                    ),
                ],
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
                  ? const Icon(LucideIcons.check, color: AppColors.background, size: 14)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
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
              constraints: const BoxConstraints(maxWidth: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isTransfer
                        ? CurrencyFormatter.format(transaction.amount)
                        : CurrencyFormatter.formatWithSign(transaction.amount, transaction.type.name),
                    style: AppTypography.moneySmall.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isTransfer)
                    Text(
                      account?.name ?? 'Unknown',
                      style: AppTypography.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
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
    return Dismissible(
      key: ValueKey(transaction.id),
      background: Container(
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
      secondaryBackground: Container(
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
      confirmDismiss: (direction) async {
        final hapticEnabled = ref.read(hapticEnabledProvider);
        await HapticHelper.mediumImpact(enabled: hapticEnabled);
        if (direction == DismissDirection.startToEnd) {
          // Duplicate: create new transaction with same details, today's date
          final tx = transaction;
          await ref.read(transactionsProvider.notifier).addTransaction(
                amount: tx.amount,
                type: tx.type,
                categoryId: tx.categoryId,
                accountId: tx.accountId,
                destinationAccountId: tx.destinationAccountId,
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
        onTap: () => context.push('/transaction/${transaction.id}'),
        onLongPress: () {
          ref.read(transactionSelectionModeProvider.notifier).state = true;
          ref.read(selectedTransactionIdsProvider.notifier).state = {transaction.id};
        },
        child: itemContent,
      ),
    );
  }
}

class _PickerItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const _PickerItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _BulkPickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;

  const _BulkPickerSheet({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textTertiary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => Navigator.pop(context, item.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, color: item.color, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(item.name, style: AppTypography.labelLarge),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
      ],
    );
  }
}
