import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/balance_history_point.dart';
import 'analytics_filter_provider.dart';

final balanceHistoryProvider = Provider<List<BalanceHistoryPoint>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final filter = ref.watch(analyticsFilterProvider);

  final transactions = transactionsAsync.valueOrNull;
  final accounts = accountsAsync.valueOrNull;

  if (transactions == null || accounts == null || accounts.isEmpty) {
    return [];
  }

  // Filter accounts if needed
  final relevantAccounts = filter.hasAccountFilter
      ? accounts.where((a) => filter.selectedAccountIds.contains(a.id)).toList()
      : accounts;

  if (relevantAccounts.isEmpty) return [];

  // Get current balances for relevant accounts
  final currentBalances = <String, double>{};
  for (final account in relevantAccounts) {
    currentBalances[account.id] = account.balance;
  }

  // Get all transactions sorted by date descending
  final sortedTransactions = List<Transaction>.from(transactions)
    ..sort((a, b) => b.date.compareTo(a.date));

  // Filter to only transactions affecting relevant accounts
  final relevantTransactions = sortedTransactions
      .where((tx) => currentBalances.containsKey(tx.accountId))
      .toList();

  // Build daily snapshots by working backwards from current balance
  final dateRange = filter.dateRange;
  final points = <BalanceHistoryPoint>[];

  // Start from today and work backwards
  var currentDate = DateTime(
    dateRange.end.year,
    dateRange.end.month,
    dateRange.end.day,
  );
  final startDate = DateTime(
    dateRange.start.year,
    dateRange.start.month,
    dateRange.start.day,
  );

  // Running balances (start with current)
  final runningBalances = Map<String, double>.from(currentBalances);

  // Index into sorted transactions
  int txIndex = 0;

  while (!currentDate.isBefore(startDate)) {
    // Process all transactions on this date (reverse their effect)
    while (txIndex < relevantTransactions.length) {
      final tx = relevantTransactions[txIndex];
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (txDate.isAfter(currentDate)) {
        // Transaction is after current date, reverse it
        final accountId = tx.accountId;
        if (runningBalances.containsKey(accountId)) {
          if (tx.type == TransactionType.income) {
            runningBalances[accountId] = runningBalances[accountId]! - tx.amount;
          } else {
            runningBalances[accountId] = runningBalances[accountId]! + tx.amount;
          }
        }
        txIndex++;
      } else {
        break;
      }
    }

    // Calculate total balance for this date
    final totalBalance = runningBalances.values.fold(0.0, (sum, b) => sum + b);

    points.add(BalanceHistoryPoint(
      date: currentDate,
      totalBalance: totalBalance,
      accountBalances: Map<String, double>.from(runningBalances),
    ));

    // Move to previous day
    currentDate = currentDate.subtract(const Duration(days: 1));
  }

  // Reverse to get chronological order
  return points.reversed.toList();
});

// Simplified version that aggregates based on date range length
final aggregatedBalanceHistoryProvider = Provider<List<BalanceHistoryPoint>>((ref) {
  final fullHistory = ref.watch(balanceHistoryProvider);
  final filter = ref.watch(analyticsFilterProvider);

  if (fullHistory.isEmpty) return [];

  final dayCount = filter.dateRange.dayCount;

  // Determine aggregation level
  int aggregationDays;
  if (dayCount <= 14) {
    aggregationDays = 1; // Daily
  } else if (dayCount <= 90) {
    aggregationDays = 7; // Weekly
  } else if (dayCount <= 365) {
    aggregationDays = 30; // Monthly
  } else {
    aggregationDays = 90; // Quarterly
  }

  if (aggregationDays == 1) return fullHistory;

  // Aggregate points
  final aggregated = <BalanceHistoryPoint>[];
  for (int i = 0; i < fullHistory.length; i += aggregationDays) {
    final endIndex = (i + aggregationDays - 1).clamp(0, fullHistory.length - 1);
    aggregated.add(fullHistory[endIndex]);
  }

  // Always include the last point
  if (aggregated.isEmpty || aggregated.last != fullHistory.last) {
    aggregated.add(fullHistory.last);
  }

  return aggregated;
});
