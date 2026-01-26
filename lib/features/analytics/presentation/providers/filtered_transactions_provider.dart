import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/analytics_filter.dart';
import 'analytics_filter_provider.dart';

final filteredAnalyticsTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  final transactions = transactionsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;

  if (transactions == null) return [];

  return transactions.where((tx) {
    // Date filter
    if (!filter.dateRange.contains(tx.date)) {
      return false;
    }

    // Account filter
    if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) {
      return false;
    }

    // Category filter (including descendants)
    if (filter.hasCategoryFilter && categories != null) {
      final matchesCategory = _matchesCategoryFilter(
        tx.categoryId,
        filter.selectedCategoryIds,
        categories,
      );
      if (!matchesCategory) {
        return false;
      }
    }

    // Type filter
    if (!filter.typeFilter.matches(tx.type)) {
      return false;
    }

    return true;
  }).toList();
});

bool _matchesCategoryFilter(
  String categoryId,
  Set<String> selectedIds,
  List<dynamic> categories,
) {
  // Direct match
  if (selectedIds.contains(categoryId)) {
    return true;
  }

  // Check if any selected category is an ancestor
  for (final selectedId in selectedIds) {
    final descendants = CategoryTreeBuilder.getDescendantIds(
      categories.cast(),
      selectedId,
    );
    if (descendants.contains(categoryId)) {
      return true;
    }
  }

  return false;
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
