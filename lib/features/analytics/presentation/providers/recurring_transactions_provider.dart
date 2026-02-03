import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/recurring_transaction.dart';

const _uuid = Uuid();

/// Detects recurring/subscription transactions from transaction history
final recurringTransactionsProvider = Provider<RecurringSummary>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final transactions = transactionsAsync.valueOrNull;

  if (transactions == null || transactions.length < 3) {
    return RecurringSummary.empty();
  }

  // Only consider expenses for subscriptions
  final expenses = transactions
      .where((tx) => tx.type == TransactionType.expense)
      .toList();

  if (expenses.length < 3) {
    return RecurringSummary.empty();
  }

  final detected = <RecurringTransaction>[];

  // Group by (rounded amount to nearest dollar, categoryId, optional merchant)
  final groups = <String, List<Transaction>>{};
  for (final tx in expenses) {
    // Create group key: amount_category_merchant
    final amountKey = tx.amount.round().toString();
    final merchantKey = tx.merchant?.toLowerCase().trim() ?? '';
    final key = '${amountKey}_${tx.categoryId}_$merchantKey';
    groups.putIfAbsent(key, () => []).add(tx);
  }

  for (final entry in groups.entries) {
    final txs = entry.value;
    if (txs.length < 3) continue;

    // Sort by date ascending
    txs.sort((a, b) => a.date.compareTo(b.date));

    // Calculate intervals between transactions
    final intervals = <int>[];
    for (int i = 1; i < txs.length; i++) {
      intervals.add(txs[i].date.difference(txs[i - 1].date).inDays);
    }

    if (intervals.isEmpty) continue;

    // Calculate average interval
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // Determine frequency based on average interval
    RecurringFrequency? frequency;
    RecurringConfidence confidence = RecurringConfidence.low;

    if (avgInterval >= 5 && avgInterval <= 9) {
      frequency = RecurringFrequency.weekly;
    } else if (avgInterval >= 12 && avgInterval <= 16) {
      frequency = RecurringFrequency.biweekly;
    } else if (avgInterval >= 25 && avgInterval <= 35) {
      frequency = RecurringFrequency.monthly;
    } else if (avgInterval >= 350 && avgInterval <= 380) {
      frequency = RecurringFrequency.yearly;
    }

    if (frequency == null) continue;

    // Calculate confidence based on interval consistency
    final variance = intervals.map((i) => (i - avgInterval).abs()).reduce((a, b) => a + b) / intervals.length;

    if (variance <= 2) {
      confidence = RecurringConfidence.high;
    } else if (variance <= 5) {
      confidence = RecurringConfidence.medium;
    } else if (variance <= 10) {
      confidence = RecurringConfidence.low;
    } else {
      continue; // Too inconsistent
    }

    // Calculate next expected date
    final lastDate = txs.last.date;
    final nextExpected = lastDate.add(Duration(days: frequency.averageDays));

    detected.add(RecurringTransaction(
      id: _uuid.v4(),
      merchant: txs.first.merchant,
      categoryId: txs.first.categoryId,
      amount: txs.first.amount,
      frequency: frequency,
      confidence: confidence,
      lastOccurrence: lastDate,
      nextExpected: nextExpected,
      matchingTransactions: txs,
      occurrenceCount: txs.length,
    ));
  }

  // Sort by monthly amount descending
  detected.sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));

  // Calculate totals
  final totalMonthly = detected.fold<double>(0, (sum, r) => sum + r.monthlyAmount);
  final totalYearly = detected.fold<double>(0, (sum, r) => sum + r.yearlyAmount);

  return RecurringSummary(
    subscriptions: detected,
    totalMonthly: totalMonthly,
    totalYearly: totalYearly,
    count: detected.length,
  );
});

/// Provides upcoming subscription payments in the next 30 days
final upcomingSubscriptionsProvider = Provider<List<RecurringTransaction>>((ref) {
  final summary = ref.watch(recurringTransactionsProvider);
  final now = DateTime.now();
  final thirtyDaysFromNow = now.add(const Duration(days: 30));

  return summary.subscriptions.where((sub) {
    if (sub.nextExpected == null) return false;
    return sub.nextExpected!.isAfter(now) && sub.nextExpected!.isBefore(thirtyDaysFromNow);
  }).toList()
    ..sort((a, b) => a.nextExpected!.compareTo(b.nextExpected!));
});

/// Provides subscriptions grouped by category
final subscriptionsByCategoryProvider = Provider<Map<String, List<RecurringTransaction>>>((ref) {
  final summary = ref.watch(recurringTransactionsProvider);
  final grouped = <String, List<RecurringTransaction>>{};

  for (final sub in summary.subscriptions) {
    grouped.putIfAbsent(sub.categoryId, () => []).add(sub);
  }

  return grouped;
});
