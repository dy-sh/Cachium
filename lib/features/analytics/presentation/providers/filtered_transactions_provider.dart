import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/analytics_filter.dart';
import 'analytics_filter_provider.dart';

final filteredAnalyticsTransactionsProvider = Provider<List<Transaction>>((ref) {
  // Keep alive so switching analytics tabs doesn't recompute the filtered list.
  ref.keepAlive();

  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  final transactions = transactionsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;

  if (transactions == null) return [];

  // Pre-compute expanded category IDs (selected + all descendants) once
  Set<String>? expandedCategoryIds;
  if (filter.hasCategoryFilter && categories != null) {
    expandedCategoryIds = _expandCategoryIds(filter.selectedCategoryIds, categories);
  }

  return transactions.where((tx) {
    // Date filter
    if (!filter.dateRange.contains(tx.date)) {
      return false;
    }

    // Account filter
    if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) {
      return false;
    }

    // Category filter (pre-computed set lookup — O(1) per transaction)
    if (expandedCategoryIds != null && !expandedCategoryIds.contains(tx.categoryId)) {
      return false;
    }

    // Type filter
    if (!filter.typeFilter.matches(tx.type)) {
      return false;
    }

    return true;
  }).toList();
});

/// Expands selected category IDs to include all descendant IDs.
/// Computed once per filter change rather than per transaction.
Set<String> _expandCategoryIds(
  Set<String> selectedIds,
  List<Category> categories,
) {
  final expanded = <String>{...selectedIds};
  for (final selectedId in selectedIds) {
    expanded.addAll(CategoryTreeBuilder.getDescendantIds(categories, selectedId));
  }
  return expanded;
}

// Convenience providers for filtered data
final filteredTransactionCountProvider = Provider<int>((ref) {
  return ref.watch(filteredAnalyticsTransactionsProvider).length;
});

final filteredIncomeTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  return transactions.where((tx) => tx.type == TransactionType.income).toList();
});

final filteredExpenseTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  return transactions.where((tx) => tx.type == TransactionType.expense).toList();
});
