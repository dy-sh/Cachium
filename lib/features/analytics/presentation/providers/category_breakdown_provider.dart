import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/analytics_filter.dart';
import '../../data/models/category_breakdown.dart';
import 'analytics_filter_provider.dart';
import 'filtered_transactions_provider.dart';

List<CategoryBreakdown> _buildBreakdowns({
  required List<Transaction> transactions,
  required List<Category> categories,
  required ColorIntensity colorIntensity,
  required CategoryType fallbackType,
  required Map<String, double> rates,
  required String mainCurrency,
}) {
  if (transactions.isEmpty) return [];

  final categoryMap = {for (final c in categories) c.id: c};

  final Map<String, double> categoryTotals = {};
  final Map<String, int> categoryCounts = {};

  for (final tx in transactions) {
    categoryTotals[tx.categoryId] =
        (categoryTotals[tx.categoryId] ?? 0) + convertedAmount(tx, rates, mainCurrency);
    categoryCounts[tx.categoryId] =
        (categoryCounts[tx.categoryId] ?? 0) + 1;
  }

  final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

  final breakdowns = <CategoryBreakdown>[];

  for (final entry in categoryTotals.entries) {
    final category = categoryMap[entry.key] ?? Category(
      id: entry.key,
      name: 'Unknown',
      icon: Icons.category,
      colorIndex: 0,
      type: fallbackType,
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
}

final categoryBreakdownProvider = Provider<List<CategoryBreakdown>>((ref) {
  // Keep alive to avoid recomputing category breakdowns when switching tabs.
  ref.keepAlive();

  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final mainCurrency = ref.watch(mainCurrencyCodeProvider);
  final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};

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

  return _buildBreakdowns(
    transactions: relevantTransactions,
    categories: categories,
    colorIntensity: colorIntensity,
    fallbackType: filter.typeFilter == AnalyticsTypeFilter.income
        ? CategoryType.income
        : CategoryType.expense,
    rates: rates,
    mainCurrency: mainCurrency,
  );
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
  final mainCurrency = ref.watch(mainCurrencyCodeProvider);
  final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};

  final categories = categoriesAsync.valueOrNull;
  if (categories == null) return [];

  final incomeTransactions = transactions
      .where((tx) => tx.type == TransactionType.income)
      .toList();

  return _buildBreakdowns(
    transactions: incomeTransactions,
    categories: categories,
    colorIntensity: colorIntensity,
    fallbackType: CategoryType.income,
    rates: rates,
    mainCurrency: mainCurrency,
  );
});
