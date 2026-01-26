import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/analytics_filter.dart';
import '../../data/models/category_breakdown.dart';
import 'analytics_filter_provider.dart';
import 'filtered_transactions_provider.dart';

final categoryBreakdownProvider = Provider<List<CategoryBreakdown>>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);
  final filter = ref.watch(analyticsFilterProvider);

  final categories = categoriesAsync.valueOrNull;
  if (categories == null || transactions.isEmpty) return [];

  // Filter transactions based on type filter
  List<Transaction> relevantTransactions;
  if (filter.typeFilter == AnalyticsTypeFilter.expense) {
    relevantTransactions = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
  } else if (filter.typeFilter == AnalyticsTypeFilter.income) {
    relevantTransactions = transactions
        .where((tx) => tx.type == TransactionType.income)
        .toList();
  } else {
    // For "all", default to expense for category breakdown
    relevantTransactions = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
  }

  if (relevantTransactions.isEmpty) return [];

  // Aggregate by category
  final Map<String, double> categoryTotals = {};
  final Map<String, int> categoryCounts = {};

  for (final tx in relevantTransactions) {
    categoryTotals[tx.categoryId] =
        (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
    categoryCounts[tx.categoryId] =
        (categoryCounts[tx.categoryId] ?? 0) + 1;
  }

  // Calculate total for percentages
  final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

  // Build breakdown with category info
  final breakdowns = <CategoryBreakdown>[];

  for (final entry in categoryTotals.entries) {
    final category = categories.firstWhere(
      (c) => c.id == entry.key,
      orElse: () => Category(
        id: entry.key,
        name: 'Unknown',
        icon: Icons.category,
        colorIndex: 0,
        type: CategoryType.expense,
      ),
    );

    breakdowns.add(CategoryBreakdown(
      categoryId: entry.key,
      name: category.name,
      icon: category.icon,
      color: category.getColor(colorIntensity),
      amount: entry.value,
      percentage: total > 0 ? (entry.value / total * 100) : 0,
      transactionCount: categoryCounts[entry.key] ?? 0,
    ));
  }

  // Sort by amount descending
  breakdowns.sort((a, b) => b.amount.compareTo(a.amount));

  return breakdowns;
});

// Top categories (limited count)
final topCategoriesProvider = Provider.family<List<CategoryBreakdown>, int>((ref, limit) {
  final breakdowns = ref.watch(categoryBreakdownProvider);
  return breakdowns.take(limit).toList();
});

// Income category breakdown
final incomeCategoryBreakdownProvider = Provider<List<CategoryBreakdown>>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);

  final categories = categoriesAsync.valueOrNull;
  if (categories == null) return [];

  final incomeTransactions = transactions
      .where((tx) => tx.type == TransactionType.income)
      .toList();

  if (incomeTransactions.isEmpty) return [];

  // Aggregate by category
  final Map<String, double> categoryTotals = {};
  final Map<String, int> categoryCounts = {};

  for (final tx in incomeTransactions) {
    categoryTotals[tx.categoryId] =
        (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
    categoryCounts[tx.categoryId] =
        (categoryCounts[tx.categoryId] ?? 0) + 1;
  }

  final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

  final breakdowns = <CategoryBreakdown>[];

  for (final entry in categoryTotals.entries) {
    final category = categories.firstWhere(
      (c) => c.id == entry.key,
      orElse: () => Category(
        id: entry.key,
        name: 'Unknown',
        icon: Icons.category,
        colorIndex: 0,
        type: CategoryType.income,
      ),
    );

    breakdowns.add(CategoryBreakdown(
      categoryId: entry.key,
      name: category.name,
      icon: category.icon,
      color: category.getColor(colorIntensity),
      amount: entry.value,
      percentage: total > 0 ? (entry.value / total * 100) : 0,
      transactionCount: categoryCounts[entry.key] ?? 0,
    ));
  }

  breakdowns.sort((a, b) => b.amount.compareTo(a.amount));

  return breakdowns;
});
