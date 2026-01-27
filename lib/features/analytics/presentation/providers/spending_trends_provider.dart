import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/date_range_preset.dart';
import '../../data/models/spending_trend.dart';
import 'analytics_filter_provider.dart';

final spendingTrendsProvider = Provider<OverallTrend>((ref) {
  final filter = ref.watch(analyticsFilterProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  final transactions = transactionsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;

  if (transactions == null || categories == null) {
    return const OverallTrend(
      currentIncome: 0,
      previousIncome: 0,
      currentExpense: 0,
      previousExpense: 0,
      incomeChangePercent: 0,
      expenseChangePercent: 0,
      topCategoryChanges: [],
    );
  }

  final currentRange = filter.dateRange;
  final dayCount = currentRange.dayCount;

  // Compute previous period of equal length
  final previousEnd = currentRange.start.subtract(const Duration(days: 1));
  final previousStart = previousEnd.subtract(Duration(days: dayCount - 1));
  final previousRange = DateRange(
    start: DateTime(previousStart.year, previousStart.month, previousStart.day),
    end: DateTime(previousEnd.year, previousEnd.month, previousEnd.day, 23, 59, 59),
  );

  // Filter transactions for both periods (respecting account/category filters)
  bool matchesFilters(Transaction tx) {
    if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) {
      return false;
    }
    if (filter.hasCategoryFilter && !filter.selectedCategoryIds.contains(tx.categoryId)) {
      return false;
    }
    return true;
  }

  final currentTxs = transactions.where((tx) =>
    currentRange.contains(tx.date) && matchesFilters(tx)).toList();
  final previousTxs = transactions.where((tx) =>
    previousRange.contains(tx.date) && matchesFilters(tx)).toList();

  double sumByType(List<Transaction> txs, TransactionType type) =>
    txs.where((t) => t.type == type).fold(0.0, (s, t) => s + t.amount);

  final currentIncome = sumByType(currentTxs, TransactionType.income);
  final previousIncome = sumByType(previousTxs, TransactionType.income);
  final currentExpense = sumByType(currentTxs, TransactionType.expense);
  final previousExpense = sumByType(previousTxs, TransactionType.expense);

  double changePercent(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous * 100);
  }

  // Per-category expense changes
  final Map<String, double> currentByCategory = {};
  final Map<String, double> previousByCategory = {};

  for (final tx in currentTxs.where((t) => t.type == TransactionType.expense)) {
    currentByCategory[tx.categoryId] =
        (currentByCategory[tx.categoryId] ?? 0) + tx.amount;
  }
  for (final tx in previousTxs.where((t) => t.type == TransactionType.expense)) {
    previousByCategory[tx.categoryId] =
        (previousByCategory[tx.categoryId] ?? 0) + tx.amount;
  }

  final allCategoryIds = {...currentByCategory.keys, ...previousByCategory.keys};
  final trends = <SpendingTrend>[];

  for (final catId in allCategoryIds) {
    final curr = currentByCategory[catId] ?? 0;
    final prev = previousByCategory[catId] ?? 0;
    final pct = changePercent(curr, prev);

    final cat = categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => Category(
        id: catId,
        name: 'Unknown',
        icon: const IconData(0),
        colorIndex: 0,
        type: CategoryType.expense,
      ),
    );

    trends.add(SpendingTrend(
      categoryId: catId,
      categoryName: cat.name,
      currentAmount: curr,
      previousAmount: prev,
      changePercent: pct,
      isIncrease: curr > prev,
    ));
  }

  // Sort by absolute change percent descending, take top 5
  trends.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));

  return OverallTrend(
    currentIncome: currentIncome,
    previousIncome: previousIncome,
    currentExpense: currentExpense,
    previousExpense: previousExpense,
    incomeChangePercent: changePercent(currentIncome, previousIncome),
    expenseChangePercent: changePercent(currentExpense, previousExpense),
    topCategoryChanges: trends.take(5).toList(),
  );
});
