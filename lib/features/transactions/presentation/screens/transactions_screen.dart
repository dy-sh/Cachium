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
                  options: const ['All', 'Income', 'Expense'],
                  selectedIndex: filter.index,
                  colors: [
                    AppColors.textPrimary,
                    AppColors.getTransactionColor('income', intensity),
                    AppColors.getTransactionColor('expense', intensity),
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
                child: CircularProgressIndicator(),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.receipt,
                            color: AppColors.textTertiary,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No transactions found',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
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

  const _SelectionHeader({
    required this.selectedCount,
    required this.onCancel,
    required this.onSelectAll,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
            onTap: selectedCount > 0 ? onDelete : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selectedCount > 0
                    ? AppColors.red.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selectedCount > 0
                      ? AppColors.red.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                LucideIcons.trash2,
                color: selectedCount > 0 ? AppColors.red : AppColors.textTertiary,
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
                _formatNetAmount(group.netAmount),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
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

  String _formatNetAmount(double amount) {
    if (amount >= 0) {
      return '+${CurrencyFormatter.format(amount)}';
    }
    return CurrencyFormatter.format(amount);
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
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatWithSign(transaction.amount, transaction.type.name),
                    style: AppTypography.moneySmall.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

    // Normal mode: swipe to delete, tap to edit, long-press to enter selection
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
        onLongPress: () {
          ref.read(transactionSelectionModeProvider.notifier).state = true;
          ref.read(selectedTransactionIdsProvider.notifier).state = {transaction.id};
        },
        child: itemContent,
      ),
    );
  }
}
