import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/asset.dart';
import 'assets_provider.dart';

/// Monthly spending data for an asset.
typedef AssetMonthlyData = ({DateTime month, double expense, double income});

/// Category breakdown entry for an asset.
typedef AssetCategoryEntry = ({
  String categoryId,
  String name,
  IconData icon,
  Color color,
  double amount,
  double percentage,
});

/// Cost breakdown for an asset.
typedef AssetCostBreakdown = ({
  double acquisitionCost,
  double runningCosts,
  double revenue,
  double netCost,
  double? profitLoss,
});

/// Computed stats for an asset.
typedef AssetStats = ({
  double monthlyAverage,
  double costPerDay,
  Duration timeOwned,
  int totalTransactions,
});

/// Transactions grouped by month.
typedef AssetMonthGroup = ({
  DateTime month,
  List<Transaction> transactions,
  double expenseSubtotal,
  double incomeSubtotal,
});

/// Groups an asset's transactions by month with expense/income totals.
final assetMonthlySpendingProvider =
    Provider.family<List<AssetMonthlyData>, String>((ref, assetId) {
  final transactions = ref.watch(transactionsByAssetProvider(assetId));
  if (transactions.isEmpty) return [];

  final Map<String, ({double expense, double income, DateTime month})> byMonth = {};

  for (final tx in transactions) {
    final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
    final month = DateTime(tx.date.year, tx.date.month);
    final existing = byMonth[key];

    double expense = existing?.expense ?? 0;
    double income = existing?.income ?? 0;

    if (tx.type == TransactionType.expense) {
      expense += tx.effectiveMainCurrencyAmount;
    } else if (tx.type == TransactionType.income) {
      income += tx.effectiveMainCurrencyAmount;
    }

    byMonth[key] = (expense: expense, income: income, month: month);
  }

  final sorted = byMonth.values.toList()
    ..sort((a, b) => a.month.compareTo(b.month));

  return sorted
      .map((e) => (month: e.month, expense: e.expense, income: e.income))
      .toList();
});

/// Cumulative net cost data points for an asset (running total of expenses - income).
/// purchasePrice is display-only metadata and not included in calculations.
final assetCumulativeCostProvider =
    Provider.family<List<({DateTime month, double cumulativeCost})>, String>((ref, assetId) {
  final monthlyData = ref.watch(assetMonthlySpendingProvider(assetId));
  if (monthlyData.isEmpty) return [];

  double running = 0;
  return monthlyData.map((d) {
    running += d.expense - d.income;
    return (month: d.month, cumulativeCost: running);
  }).toList();
});

/// Expense categories breakdown for an asset.
final assetCategoryBreakdownProvider =
    Provider.family<List<AssetCategoryEntry>, String>((ref, assetId) {
  final transactions = ref.watch(transactionsByAssetProvider(assetId));
  final intensity = ref.watch(colorIntensityProvider);

  final expenses = transactions.where((tx) => tx.type == TransactionType.expense).toList();
  if (expenses.isEmpty) return [];

  final double totalExpense = expenses.fold(0, (sum, tx) => sum + tx.effectiveMainCurrencyAmount);

  final Map<String, double> byCategoryId = {};
  for (final tx in expenses) {
    byCategoryId[tx.categoryId] = (byCategoryId[tx.categoryId] ?? 0) + tx.effectiveMainCurrencyAmount;
  }

  final entries = <AssetCategoryEntry>[];
  for (final entry in byCategoryId.entries) {
    final category = ref.watch(categoryByIdProvider(entry.key));
    entries.add((
      categoryId: entry.key,
      name: category?.name ?? 'Unknown',
      icon: category?.icon ?? Icons.circle,
      color: category?.getColor(intensity) ?? Colors.grey,
      amount: entry.value,
      percentage: totalExpense > 0 ? entry.value / totalExpense : 0,
    ));
  }

  entries.sort((a, b) => b.amount.compareTo(a.amount));
  return entries;
});

/// Cost breakdown: total expenses vs revenue vs net cost.
/// All calculations are driven by linked transactions only.
/// purchasePrice is display-only metadata shown in the hero card.
/// When a sold asset has a salePrice but no income transactions, salePrice is
/// used as revenue fallback.
final assetCostBreakdownProvider =
    Provider.family<AssetCostBreakdown, String>((ref, assetId) {
  final asset = ref.watch(assetByIdProvider(assetId));
  final transactions = ref.watch(transactionsByAssetProvider(assetId));

  double totalExpenses = 0;
  double revenue = 0;

  for (final tx in transactions) {
    if (tx.type == TransactionType.expense) {
      totalExpenses += tx.effectiveMainCurrencyAmount;
    } else if (tx.type == TransactionType.income) {
      revenue += tx.effectiveMainCurrencyAmount;
    }
  }

  // Fallback: use stored salePrice as revenue when no income transactions exist
  if (asset?.status == AssetStatus.sold &&
      asset?.salePrice != null &&
      revenue == 0) {
    revenue = asset!.salePrice!;
  }

  final netCost = totalExpenses - revenue;
  final profitLoss = (asset?.status == AssetStatus.sold)
      ? revenue - totalExpenses
      : null;

  return (
    acquisitionCost: 0,
    runningCosts: totalExpenses,
    revenue: revenue,
    netCost: netCost,
    profitLoss: profitLoss,
  );
});

/// Computed summary statistics for an asset.
final assetStatsProvider =
    Provider.family<AssetStats, String>((ref, assetId) {
  final transactions = ref.watch(transactionsByAssetProvider(assetId));
  final asset = ref.watch(assetByIdProvider(assetId));

  double totalExpense = 0;
  for (final tx in transactions) {
    if (tx.type == TransactionType.expense) {
      totalExpense += tx.effectiveMainCurrencyAmount;
    }
  }

  final endDate = (asset?.status == AssetStatus.sold && asset?.soldDate != null)
      ? asset!.soldDate!
      : DateTime.now();
  final startDate = asset?.purchaseDate ?? asset?.createdAt ?? endDate;
  final timeOwned = endDate.difference(startDate);
  final daysOwned = timeOwned.inDays.clamp(1, double.maxFinite).toInt();

  // Monthly average based on months owned
  final monthsOwned = ((endDate.year - startDate.year) * 12 +
          (endDate.month - startDate.month))
      .clamp(1, double.maxFinite)
      .toInt();
  final monthlyAverage = totalExpense / monthsOwned;
  final costPerDay = totalExpense / daysOwned;

  return (
    monthlyAverage: monthlyAverage,
    costPerDay: costPerDay,
    timeOwned: timeOwned,
    totalTransactions: transactions.length,
  );
});

/// Transactions grouped by month (descending) with subtotals.
final assetTransactionsByMonthProvider =
    Provider.family<List<AssetMonthGroup>, String>((ref, assetId) {
  final transactions = ref.watch(transactionsByAssetProvider(assetId));
  if (transactions.isEmpty) return [];

  final Map<String, List<Transaction>> byMonth = {};

  for (final tx in transactions) {
    final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
    byMonth.putIfAbsent(key, () => []).add(tx);
  }

  final groups = <AssetMonthGroup>[];
  for (final entry in byMonth.entries) {
    final txs = entry.value..sort((a, b) => b.date.compareTo(a.date));
    final month = DateTime(txs.first.date.year, txs.first.date.month);
    double expenseSubtotal = 0;
    double incomeSubtotal = 0;
    for (final tx in txs) {
      if (tx.type == TransactionType.expense) {
        expenseSubtotal += tx.effectiveMainCurrencyAmount;
      } else if (tx.type == TransactionType.income) {
        incomeSubtotal += tx.effectiveMainCurrencyAmount;
      }
    }
    groups.add((
      month: month,
      transactions: txs,
      expenseSubtotal: expenseSubtotal,
      incomeSubtotal: incomeSubtotal,
    ));
  }

  groups.sort((a, b) => b.month.compareTo(a.month));
  return groups;
});
