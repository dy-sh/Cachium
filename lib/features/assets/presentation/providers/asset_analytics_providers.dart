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
  bool revenueFromSalePrice,
});

/// Computed stats for an asset.
typedef AssetStats = ({
  double monthlyAverage,
  double costPerDay,
  Duration timeOwned,
  int totalTransactions,
});

/// Yearly cost data for an asset.
typedef AssetYearlyData = ({int year, double expense, double income});

/// Value over time data point for an asset.
typedef AssetValuePoint = ({DateTime month, double value});

/// Transactions grouped by month.
typedef AssetMonthGroup = ({
  DateTime month,
  List<Transaction> transactions,
  double expenseSubtotal,
  double incomeSubtotal,
});

/// Selected date range for asset detail screen filtering.
/// null means "All Time".
final assetDetailDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

/// Asset transactions filtered by the selected date range.
final filteredTransactionsByAssetProvider =
    Provider.family<List<Transaction>, String>((ref, assetId) {
  final transactions = ref.watch(transactionsByAssetProvider(assetId));
  final range = ref.watch(assetDetailDateRangeProvider);
  if (range == null) return transactions;
  return transactions.where((tx) =>
    !tx.date.isBefore(range.start) && !tx.date.isAfter(range.end),
  ).toList();
});

/// Groups an asset's transactions by month with expense/income totals.
final assetMonthlySpendingProvider =
    Provider.family<List<AssetMonthlyData>, String>((ref, assetId) {
  final transactions = ref.watch(filteredTransactionsByAssetProvider(assetId));
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
  final transactions = ref.watch(filteredTransactionsByAssetProvider(assetId));
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
  final transactions = ref.watch(filteredTransactionsByAssetProvider(assetId));

  double totalExpenses = 0;
  double acquisitionCost = 0;
  double revenue = 0;
  final assetName = asset?.name.toLowerCase() ?? '';

  for (final tx in transactions) {
    if (tx.type == TransactionType.expense) {
      totalExpenses += tx.effectiveMainCurrencyAmount;
      // Use explicit flag, with legacy note-matching fallback for old data
      if (tx.isAcquisitionCost) {
        acquisitionCost += tx.effectiveMainCurrencyAmount;
      } else if (assetName.isNotEmpty) {
        final note = tx.note?.toLowerCase() ?? '';
        if (note.startsWith('purchase of ') && note.contains(assetName)) {
          acquisitionCost += tx.effectiveMainCurrencyAmount;
        }
      }
    } else if (tx.type == TransactionType.income) {
      revenue += tx.effectiveMainCurrencyAmount;
    }
  }

  // Fallback: use stored salePrice as revenue when no income transactions exist
  bool revenueFromSalePrice = false;
  if (asset?.status == AssetStatus.sold &&
      asset?.salePrice != null &&
      revenue == 0) {
    revenue = asset!.salePrice!;
    revenueFromSalePrice = true;
  }

  final runningCosts = totalExpenses - acquisitionCost;
  final netCost = totalExpenses - revenue;
  final profitLoss = (asset?.status == AssetStatus.sold)
      ? revenue - totalExpenses
      : null;

  return (
    acquisitionCost: acquisitionCost,
    runningCosts: runningCosts,
    revenue: revenue,
    netCost: netCost,
    profitLoss: profitLoss,
    revenueFromSalePrice: revenueFromSalePrice,
  );
});

/// Computed summary statistics for an asset.
final assetStatsProvider =
    Provider.family<AssetStats, String>((ref, assetId) {
  final transactions = ref.watch(filteredTransactionsByAssetProvider(assetId));
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
  final transactions = ref.watch(filteredTransactionsByAssetProvider(assetId));
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

/// ROI percentage for a sold asset: ((revenue - totalCosts) / totalCosts) * 100.
/// Returns null if asset is not sold or has no costs.
final assetROIProvider = Provider.family<double?, String>((ref, assetId) {
  final breakdown = ref.watch(assetCostBreakdownProvider(assetId));
  if (breakdown.profitLoss == null) return null;
  final totalCosts = breakdown.acquisitionCost + breakdown.runningCosts;
  if (totalCosts <= 0) return null;
  return (breakdown.profitLoss! / totalCosts) * 100;
});

/// Most-used expense category for an asset (by transaction count).
/// Returns null if the asset has no expense transactions.
final assetTopCategoryProvider = Provider.family<String?, String>((ref, assetId) {
  final transactions = ref.watch(transactionsByAssetProvider(assetId));
  final expenses = transactions.where((tx) => tx.type == TransactionType.expense);
  if (expenses.isEmpty) return null;

  final Map<String, int> counts = {};
  for (final tx in expenses) {
    counts[tx.categoryId] = (counts[tx.categoryId] ?? 0) + 1;
  }

  String? topId;
  int topCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > topCount) {
      topCount = entry.value;
      topId = entry.key;
    }
  }
  return topId;
});

/// Asset value over time: starts at purchasePrice, adjusts by monthly
/// expenses (decrease) and income (increase). Ends at salePrice if sold.
final assetValueOverTimeProvider =
    Provider.family<List<AssetValuePoint>, String>((ref, assetId) {
  final asset = ref.watch(assetByIdProvider(assetId));
  if (asset?.purchasePrice == null) return [];
  final monthlyData = ref.watch(assetMonthlySpendingProvider(assetId));

  double value = asset!.purchasePrice!;
  final points = <AssetValuePoint>[];

  final startDate = asset.purchaseDate ?? asset.createdAt;
  points.add((month: DateTime(startDate.year, startDate.month), value: value));

  for (final d in monthlyData) {
    value = value - d.expense + d.income;
    points.add((month: d.month, value: value));
  }

  if (asset.status == AssetStatus.sold && asset.salePrice != null) {
    final soldMonth = asset.soldDate ?? DateTime.now();
    points.add((month: DateTime(soldMonth.year, soldMonth.month), value: asset.salePrice!));
  }

  return points;
});

/// Year-over-year cost data for an asset.
final assetYearlyCostProvider =
    Provider.family<List<AssetYearlyData>, String>((ref, assetId) {
  final transactions = ref.watch(filteredTransactionsByAssetProvider(assetId));
  if (transactions.isEmpty) return [];

  final Map<int, ({double expense, double income})> byYear = {};

  for (final tx in transactions) {
    final year = tx.date.year;
    final existing = byYear[year];
    double expense = existing?.expense ?? 0;
    double income = existing?.income ?? 0;

    if (tx.type == TransactionType.expense) {
      expense += tx.effectiveMainCurrencyAmount;
    } else if (tx.type == TransactionType.income) {
      income += tx.effectiveMainCurrencyAmount;
    }

    byYear[year] = (expense: expense, income: income);
  }

  final sorted = byYear.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return sorted
      .map((e) => (year: e.key, expense: e.value.expense, income: e.value.income))
      .toList();
});

/// Portfolio category breakdown: aggregates all asset-linked transactions by category.
final portfolioCategoryBreakdownProvider =
    Provider<List<AssetCategoryEntry>>((ref) {
  final allAssets = ref.watch(assetsProvider).valueOrNull ?? [];
  final intensity = ref.watch(colorIntensityProvider);
  if (allAssets.isEmpty) return [];

  double totalExpense = 0;
  final Map<String, double> byCategoryId = {};

  for (final asset in allAssets) {
    final transactions = ref.watch(transactionsByAssetProvider(asset.id));
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final amount = tx.effectiveMainCurrencyAmount;
        totalExpense += amount;
        byCategoryId[tx.categoryId] = (byCategoryId[tx.categoryId] ?? 0) + amount;
      }
    }
  }

  if (totalExpense <= 0) return [];

  final entries = <AssetCategoryEntry>[];
  for (final entry in byCategoryId.entries) {
    final category = ref.watch(categoryByIdProvider(entry.key));
    entries.add((
      categoryId: entry.key,
      name: category?.name ?? 'Unknown',
      icon: category?.icon ?? Icons.circle,
      color: category?.getColor(intensity) ?? Colors.grey,
      amount: entry.value,
      percentage: entry.value / totalExpense,
    ));
  }

  entries.sort((a, b) => b.amount.compareTo(a.amount));
  return entries;
});
