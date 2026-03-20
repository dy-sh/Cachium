import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_selection_provider.dart';
import '../providers/transactions_provider.dart';
import 'transaction_bulk_actions.dart';
import 'transaction_filter_bar.dart';
import 'transaction_list_view.dart';

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
      builder: (context) => BulkPickerSheet(
        title: 'Change Category',
        items: categories
            .where((c) => c.parentId == null || true) // all categories
            .map((c) => BulkPickerItem(
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

    // Capture old category IDs for undo
    final oldCategoryIds = {for (final tx in toUpdate) tx.id: tx.categoryId};

    await db.transaction(() async {
      for (final tx in toUpdate) {
        final updated = tx.copyWith(categoryId: selectedCategoryId);
        await repo.updateTransaction(updated);
      }
    });

    await ref.read(transactionsProvider.notifier).refresh();
    _exitSelectionMode();

    if (mounted) {
      context.showUndoNotification(
        '${toUpdate.length} transaction${toUpdate.length == 1 ? '' : 's'} updated',
        () async {
          final undoRepo = ref.read(transactionRepositoryProvider);
          final undoDb = ref.read(databaseProvider);
          final currentTransactions = ref.read(transactionsProvider).valueOrNull ?? [];
          await undoDb.transaction(() async {
            for (final tx in currentTransactions) {
              final oldCategoryId = oldCategoryIds[tx.id];
              if (oldCategoryId != null && tx.categoryId != oldCategoryId) {
                await undoRepo.updateTransaction(tx.copyWith(categoryId: oldCategoryId));
              }
            }
          });
          await ref.read(transactionsProvider.notifier).refresh();
        },
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
      builder: (context) => BulkPickerSheet(
        title: 'Change Account',
        items: accounts
            .map((a) => BulkPickerItem(
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

    // Capture old account IDs for undo
    final oldAccountIds = {for (final tx in toUpdate) tx.id: tx.accountId};

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
      context.showUndoNotification(
        '${toUpdate.length} transaction${toUpdate.length == 1 ? '' : 's'} updated',
        () async {
          final undoRepo = ref.read(transactionRepositoryProvider);
          final undoDb = ref.read(databaseProvider);
          final currentTransactions = ref.read(transactionsProvider).valueOrNull ?? [];

          await undoDb.transaction(() async {
            for (final tx in currentTransactions) {
              final oldAccountId = oldAccountIds[tx.id];
              if (oldAccountId != null && tx.accountId != oldAccountId) {
                // Reverse balance adjustments
                if (tx.type == TransactionType.transfer) {
                  await ref.read(accountsProvider.notifier).updateBalance(tx.accountId, tx.amount);
                  await ref.read(accountsProvider.notifier).updateBalance(oldAccountId, -tx.amount);
                } else {
                  final reverseChange = tx.type == TransactionType.income ? -tx.amount : tx.amount;
                  await ref.read(accountsProvider.notifier).updateBalance(tx.accountId, reverseChange);
                  final applyChange = tx.type == TransactionType.income ? tx.amount : -tx.amount;
                  await ref.read(accountsProvider.notifier).updateBalance(oldAccountId, applyChange);
                }

                await undoRepo.updateTransaction(tx.copyWith(accountId: oldAccountId));
              }
            }
          });
          await ref.read(transactionsProvider.notifier).refresh();
        },
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
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
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
      if (value == 'deleted' && context.mounted) {
        context.push(AppRoutes.deletedTransactions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(paginatedTransactionsProvider);
    final hasMore = ref.watch(hasMoreTransactionsProvider);
    final isSelectionMode = ref.watch(transactionSelectionModeProvider);
    final selectedCount = ref.watch(selectedCountProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          if (isSelectionMode)
            SelectionHeader(
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

          // Search & filter bar
          TransactionFilterBar(
            onSearchChanged: (value) {
              ref.read(transactionSearchQueryProvider.notifier).state = value;
            },
            onFilterChanged: (index) {
              ref.read(transactionFilterProvider.notifier).state =
                  TransactionFilter.values[index];
            },
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
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: () => ref.invalidate(transactionsProvider),
                      child: Text(
                        'Try Again',
                        style: AppTypography.bodyMedium.copyWith(
                          color: ref.watch(accentColorProvider),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (groups) => TransactionListView(
                groups: groups,
                isInitialLoad: _isInitialLoad,
                hasMore: hasMore,
                onRefresh: () {
                  ref.read(transactionsProvider.notifier).refresh();
                },
                onLoadMore: () {
                  final current = ref.read(transactionDisplayCountProvider);
                  ref.read(transactionDisplayCountProvider.notifier).state =
                      current + 50;
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
              IconBtn(
                icon: LucideIcons.moreHorizontal,
                onPressed: onMore,
                iconColor: AppColors.textSecondary,
                showBorder: true,
                semanticLabel: 'More options',
              ),
              const SizedBox(width: AppSpacing.sm),
              IconBtn(
                icon: LucideIcons.plus,
                onPressed: onAdd,
                iconColor: accentColor,
                showBorder: true,
                semanticLabel: 'Add transaction',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
