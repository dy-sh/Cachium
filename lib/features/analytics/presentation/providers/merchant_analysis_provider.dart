import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/merchant_breakdown.dart';
import 'analytics_filter_provider.dart';

/// Provides merchant analysis for transactions with merchant data
final merchantAnalysisProvider = Provider<MerchantSummary>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final transactions = transactionsAsync.valueOrNull;

  if (transactions == null || transactions.isEmpty) {
    return MerchantSummary.empty();
  }

  // Filter to expenses with merchant data in current period
  final merchantExpenses = transactions.where((tx) {
    return tx.type == TransactionType.expense &&
        tx.merchant != null &&
        tx.merchant!.isNotEmpty &&
        filter.dateRange.contains(tx.date);
  }).toList();

  if (merchantExpenses.isEmpty) {
    return MerchantSummary.empty();
  }

  // Group by merchant (case-insensitive)
  final merchantGroups = <String, List<Transaction>>{};
  for (final tx in merchantExpenses) {
    final normalizedMerchant = tx.merchant!.toLowerCase().trim();
    merchantGroups.putIfAbsent(normalizedMerchant, () => []).add(tx);
  }

  // Build breakdowns
  final breakdowns = <MerchantBreakdown>[];
  for (final entry in merchantGroups.entries) {
    final txs = entry.value;
    final totalAmount = txs.fold<double>(0, (sum, tx) => sum + tx.amount);
    final avgAmount = totalAmount / txs.length;

    // Find primary category (most used)
    final categoryCount = <String, int>{};
    for (final tx in txs) {
      categoryCount[tx.categoryId] = (categoryCount[tx.categoryId] ?? 0) + 1;
    }
    final primaryCategory = categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Get the display name (use first transaction's original casing)
    final displayName = txs.first.merchant!;

    // Get last transaction date
    txs.sort((a, b) => b.date.compareTo(a.date));
    final lastTx = txs.first.date;

    breakdowns.add(MerchantBreakdown(
      merchant: displayName,
      totalAmount: totalAmount,
      transactionCount: txs.length,
      primaryCategoryId: primaryCategory,
      averageTransaction: avgAmount,
      lastTransaction: lastTx,
    ));
  }

  // Sort by total amount descending
  breakdowns.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

  final totalSpending = breakdowns.fold<double>(0, (sum, b) => sum + b.totalAmount);

  return MerchantSummary(
    topMerchants: breakdowns.take(20).toList(),
    totalMerchants: breakdowns.length,
    totalSpending: totalSpending,
    topMerchant: breakdowns.isNotEmpty ? breakdowns.first.merchant : null,
    topMerchantAmount: breakdowns.isNotEmpty ? breakdowns.first.totalAmount : null,
  );
});

/// Provides spending by merchant over time for trend charts
final merchantTrendsProvider = Provider<Map<String, List<_MerchantDataPoint>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final transactions = transactionsAsync.valueOrNull;

  if (transactions == null) return {};

  // Get expenses with merchants from the last 90 days
  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 90));

  final merchantExpenses = transactions.where((tx) {
    return tx.type == TransactionType.expense &&
        tx.merchant != null &&
        tx.merchant!.isNotEmpty &&
        tx.date.isAfter(cutoff);
  }).toList();

  if (merchantExpenses.isEmpty) return {};

  // Group by merchant and month
  final merchantMonthly = <String, Map<DateTime, double>>{};
  for (final tx in merchantExpenses) {
    final normalizedMerchant = tx.merchant!.toLowerCase().trim();
    final monthKey = DateTime(tx.date.year, tx.date.month, 1);

    merchantMonthly.putIfAbsent(normalizedMerchant, () => {});
    merchantMonthly[normalizedMerchant]![monthKey] =
        (merchantMonthly[normalizedMerchant]![monthKey] ?? 0) + tx.amount;
  }

  // Convert to data points
  final result = <String, List<_MerchantDataPoint>>{};
  for (final entry in merchantMonthly.entries) {
    final points = entry.value.entries
        .map((e) => _MerchantDataPoint(date: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    result[entry.key] = points;
  }

  return result;
});

class _MerchantDataPoint {
  final DateTime date;
  final double amount;

  const _MerchantDataPoint({required this.date, required this.amount});
}
