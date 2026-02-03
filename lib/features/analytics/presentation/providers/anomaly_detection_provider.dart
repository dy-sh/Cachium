import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/spending_anomaly.dart';
import 'analytics_filter_provider.dart';

const _uuid = Uuid();

/// Detects spending anomalies in transactions
final anomalyDetectionProvider = Provider<List<SpendingAnomaly>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final transactions = transactionsAsync.valueOrNull;

  if (transactions == null || transactions.length < 5) {
    return [];
  }

  final anomalies = <SpendingAnomaly>[];
  final now = DateTime.now();

  // Only look at expenses
  final expenses = transactions
      .where((tx) => tx.type == TransactionType.expense)
      .toList();

  if (expenses.length < 5) return [];

  // Calculate category statistics
  final categoryStats = <String, _CategoryStats>{};
  for (final tx in expenses) {
    categoryStats.putIfAbsent(tx.categoryId, () => _CategoryStats());
    categoryStats[tx.categoryId]!.amounts.add(tx.amount);
    categoryStats[tx.categoryId]!.transactions.add(tx);
  }

  // Calculate mean and std dev for each category
  for (final entry in categoryStats.entries) {
    final stats = entry.value;
    if (stats.amounts.length < 3) continue;

    final mean = stats.amounts.reduce((a, b) => a + b) / stats.amounts.length;
    final variance = stats.amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / stats.amounts.length;
    final stdDev = sqrt(variance);

    stats.mean = mean;
    stats.stdDev = stdDev;
  }

  // Detect unusual transactions (> 2 std devs from mean)
  for (final tx in expenses) {
    final stats = categoryStats[tx.categoryId];
    if (stats == null || stats.stdDev == 0) continue;

    final zScore = (tx.amount - stats.mean) / stats.stdDev;
    if (zScore > 2) {
      final percentAbove = ((tx.amount / stats.mean) - 1) * 100;
      anomalies.add(SpendingAnomaly(
        id: _uuid.v4(),
        type: AnomalyType.unusualTransaction,
        severity: zScore > 3 ? AnomalySeverity.high : AnomalySeverity.medium,
        message: 'Transaction ${percentAbove.toStringAsFixed(0)}% above category average',
        categoryId: tx.categoryId,
        transaction: tx,
        amount: tx.amount,
        averageAmount: stats.mean,
        percentageAboveAverage: percentAbove,
        detectedAt: now,
      ));
    }
  }

  // Detect category spending spikes (current period vs previous)
  final periodTransactions = expenses.where((tx) {
    return filter.dateRange.contains(tx.date);
  }).toList();

  final previousStart = filter.dateRange.start.subtract(
    Duration(days: filter.dateRange.dayCount),
  );
  final previousEnd = filter.dateRange.start.subtract(const Duration(days: 1));

  final previousTransactions = expenses.where((tx) {
    return tx.date.isAfter(previousStart) && tx.date.isBefore(previousEnd.add(const Duration(days: 1)));
  }).toList();

  // Compare category totals
  final currentCategoryTotals = <String, double>{};
  final previousCategoryTotals = <String, double>{};

  for (final tx in periodTransactions) {
    currentCategoryTotals[tx.categoryId] =
        (currentCategoryTotals[tx.categoryId] ?? 0) + tx.amount;
  }

  for (final tx in previousTransactions) {
    previousCategoryTotals[tx.categoryId] =
        (previousCategoryTotals[tx.categoryId] ?? 0) + tx.amount;
  }

  for (final categoryId in currentCategoryTotals.keys) {
    final current = currentCategoryTotals[categoryId] ?? 0;
    final previous = previousCategoryTotals[categoryId] ?? 0;

    if (previous > 0 && current > previous * 1.5) {
      final percentIncrease = ((current / previous) - 1) * 100;
      anomalies.add(SpendingAnomaly(
        id: _uuid.v4(),
        type: AnomalyType.spendingSpike,
        severity: percentIncrease > 100 ? AnomalySeverity.high : AnomalySeverity.medium,
        message: 'Category spending up ${percentIncrease.toStringAsFixed(0)}% vs last period',
        categoryId: categoryId,
        amount: current,
        averageAmount: previous,
        percentageAboveAverage: percentIncrease,
        detectedAt: now,
      ));
    }
  }

  // Sort by severity
  anomalies.sort((a, b) {
    final severityOrder = {
      AnomalySeverity.high: 0,
      AnomalySeverity.medium: 1,
      AnomalySeverity.low: 2,
    };
    return severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
  });

  return anomalies.take(10).toList();
});

class _CategoryStats {
  List<double> amounts = [];
  List<Transaction> transactions = [];
  double mean = 0;
  double stdDev = 0;
}
