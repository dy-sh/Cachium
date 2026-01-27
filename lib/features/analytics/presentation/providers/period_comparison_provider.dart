import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../data/models/analytics_filter.dart';
import '../../data/models/date_range_preset.dart';
import '../../data/models/period_comparison.dart';
import 'analytics_filter_provider.dart';

final comparisonPeriodAProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  return DateRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month, now.day, 23, 59, 59),
  );
});

final comparisonPeriodBProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1, 1);
  final lastDay = DateTime(now.year, now.month, 0, 23, 59, 59);
  return DateRange(start: lastMonth, end: lastDay);
});

final periodComparisonDataProvider = Provider<PeriodComparisonData>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final periodA = ref.watch(comparisonPeriodAProvider);
  final periodB = ref.watch(comparisonPeriodBProvider);

  final transactions = transactionsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;
  if (transactions == null) {
    return PeriodComparisonData(
      periodA: const PeriodMetrics(label: 'Period A', income: 0, expense: 0, transactionCount: 0),
      periodB: const PeriodMetrics(label: 'Period B', income: 0, expense: 0, transactionCount: 0),
      categoryComparison: [],
    );
  }

  // Apply account/category/type filters but use custom date ranges
  List<Transaction> filterForRange(DateRange range) {
    return transactions.where((tx) {
      if (!range.contains(tx.date)) return false;
      if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) return false;
      if (filter.hasCategoryFilter && categories != null) {
        if (!_matchesCategoryFilter(tx.categoryId, filter.selectedCategoryIds, categories)) return false;
      }
      if (!filter.typeFilter.matches(tx.type)) return false;
      return true;
    }).toList();
  }

  final txA = filterForRange(periodA);
  final txB = filterForRange(periodB);

  PeriodMetrics buildMetrics(String label, List<Transaction> txs) {
    double income = 0, expense = 0;
    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    return PeriodMetrics(label: label, income: income, expense: expense, transactionCount: txs.length);
  }

  // Category comparison
  final Map<String, double> catAmountsA = {};
  final Map<String, double> catAmountsB = {};
  final Map<String, String> catNames = {};

  for (final tx in txA) {
    catAmountsA[tx.categoryId] = (catAmountsA[tx.categoryId] ?? 0) + tx.amount;
  }
  for (final tx in txB) {
    catAmountsB[tx.categoryId] = (catAmountsB[tx.categoryId] ?? 0) + tx.amount;
  }

  final allCatIds = {...catAmountsA.keys, ...catAmountsB.keys};
  if (categories != null) {
    for (final cat in categories) {
      catNames[cat.id] = cat.name;
    }
  }

  final catComparison = allCatIds.map((id) {
    return CategoryComparisonItem(
      categoryId: id,
      name: catNames[id] ?? 'Unknown',
      amountA: catAmountsA[id] ?? 0,
      amountB: catAmountsB[id] ?? 0,
    );
  }).toList()
    ..sort((a, b) => (b.amountA + b.amountB).compareTo(a.amountA + a.amountB));

  return PeriodComparisonData(
    periodA: buildMetrics('Period A', txA),
    periodB: buildMetrics('Period B', txB),
    categoryComparison: catComparison.take(10).toList(),
  );
});

bool _matchesCategoryFilter(String categoryId, Set<String> selectedIds, List<dynamic> categories) {
  if (selectedIds.contains(categoryId)) return true;
  for (final selectedId in selectedIds) {
    final descendants = CategoryTreeBuilder.getDescendantIds(categories.cast(), selectedId);
    if (descendants.contains(categoryId)) return true;
  }
  return false;
}
