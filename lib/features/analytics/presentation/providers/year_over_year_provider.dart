import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../data/models/analytics_filter.dart';
import '../../data/models/year_over_year_summary.dart';
import 'analytics_filter_provider.dart';

final yoyGroupingProvider = StateProvider<YoYGrouping>((ref) => YoYGrouping.monthly);

final yoySelectedYearsProvider = StateProvider<Set<int>>((ref) {
  final now = DateTime.now();
  return {now.year, now.year - 1, now.year - 2};
});

final yoyAvailableYearsProvider = Provider<List<int>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final transactions = transactionsAsync.valueOrNull;
  if (transactions == null || transactions.isEmpty) return [];

  final years = transactions.map((tx) => tx.date.year).toSet().toList()..sort();
  return years.reversed.toList();
});

/// Aggregates transactions by year+period, applying account/category/type filters
/// but ignoring date range (since YoY needs multi-year data).
final yearOverYearDataProvider = Provider<List<YearOverYearSummary>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final grouping = ref.watch(yoyGroupingProvider);
  final selectedYears = ref.watch(yoySelectedYearsProvider);

  final transactions = transactionsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;
  if (transactions == null || selectedYears.isEmpty) return [];

  // Filter transactions (skip date range, apply account/category/type)
  final filtered = transactions.where((tx) {
    if (!selectedYears.contains(tx.date.year)) return false;

    if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) {
      return false;
    }

    if (filter.hasCategoryFilter && categories != null) {
      final matches = _matchesCategoryFilter(tx.categoryId, filter.selectedCategoryIds, categories);
      if (!matches) return false;
    }

    if (!filter.typeFilter.matches(tx.type)) return false;

    return true;
  }).toList();

  // Group by year -> period
  final Map<int, Map<int, _Accumulator>> yearPeriods = {};
  for (final year in selectedYears) {
    yearPeriods[year] = {};
  }

  for (final tx in filtered) {
    final year = tx.date.year;
    final periodIndex = grouping == YoYGrouping.monthly
        ? tx.date.month
        : ((tx.date.month - 1) ~/ 3) + 1;

    yearPeriods[year] ??= {};
    yearPeriods[year]![periodIndex] ??= _Accumulator();

    if (tx.type == TransactionType.income) {
      yearPeriods[year]![periodIndex]!.income += tx.amount;
    } else {
      yearPeriods[year]![periodIndex]!.expense += tx.amount;
    }
  }

  final labels = grouping == YoYGrouping.monthly
      ? ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      : ['', 'Q1', 'Q2', 'Q3', 'Q4'];

  final periodCount = grouping == YoYGrouping.monthly ? 12 : 4;

  final sortedYears = selectedYears.toList()..sort();
  return sortedYears.map((year) {
    final periods = List.generate(periodCount, (i) {
      final idx = i + 1;
      final acc = yearPeriods[year]?[idx];
      return YoYPeriodData(
        periodIndex: idx,
        label: labels[idx],
        income: acc?.income ?? 0,
        expense: acc?.expense ?? 0,
      );
    });
    return YearOverYearSummary(year: year, periods: periods);
  }).toList();
});

class _Accumulator {
  double income = 0;
  double expense = 0;
}

bool _matchesCategoryFilter(
  String categoryId,
  Set<String> selectedIds,
  List<dynamic> categories,
) {
  if (selectedIds.contains(categoryId)) return true;
  for (final selectedId in selectedIds) {
    final descendants = CategoryTreeBuilder.getDescendantIds(
      categories.cast(),
      selectedId,
    );
    if (descendants.contains(categoryId)) return true;
  }
  return false;
}
