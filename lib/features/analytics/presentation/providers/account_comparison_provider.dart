import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/account_comparison.dart';
import 'filtered_transactions_provider.dart';
import 'analytics_filter_provider.dart';

final selectedComparisonAccountIdsProvider = StateProvider<Set<String>>((ref) => {});

final accountComparisonDataProvider = Provider<List<AccountComparisonData>>((ref) {
  final selectedIds = ref.watch(selectedComparisonAccountIdsProvider);
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final filter = ref.watch(analyticsFilterProvider);

  final accounts = accountsAsync.valueOrNull;
  if (accounts == null || selectedIds.isEmpty) return [];

  final accountMap = <String, Account>{};
  for (final a in accounts) {
    accountMap[a.id] = a;
  }

  final start = filter.dateRange.start;
  final end = filter.dateRange.end;
  final days = end.difference(start).inDays + 1;

  String Function(DateTime) getKey;
  String Function(DateTime) getLabel;
  if (days <= 14) {
    getKey = (d) => '${d.year}-${d.month}-${d.day}';
    getLabel = (d) => DateFormat('d MMM').format(d);
  } else if (days <= 90) {
    getKey = (d) {
      final weekStart = d.subtract(Duration(days: d.weekday - 1));
      return '${weekStart.year}-${weekStart.month}-${weekStart.day}';
    };
    getLabel = (d) {
      final weekStart = d.subtract(Duration(days: d.weekday - 1));
      return DateFormat('d MMM').format(weekStart);
    };
  } else {
    getKey = (d) => '${d.year}-${d.month}';
    getLabel = (d) => DateFormat('MMM yy').format(d);
  }

  // Build ordered period keys
  final orderedKeys = <String>[];
  final keyToDate = <String, DateTime>{};
  final keyToLabel = <String, String>{};
  var cursor = start;
  while (!cursor.isAfter(end)) {
    final k = getKey(cursor);
    if (!keyToDate.containsKey(k)) {
      orderedKeys.add(k);
      keyToDate[k] = cursor;
      keyToLabel[k] = getLabel(cursor);
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  return selectedIds.where((id) => accountMap.containsKey(id)).map((id) {
    final account = accountMap[id]!;
    final accountTxs = transactions.where((tx) => tx.accountId == id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double totalIncome = 0, totalExpense = 0;
    final Map<String, double> periodNet = {};

    for (final tx in accountTxs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
      final k = getKey(tx.date);
      periodNet[k] = (periodNet[k] ?? 0) + (tx.type == TransactionType.income ? tx.amount : -tx.amount);
    }

    // Build cumulative balance history
    double runningBalance = account.initialBalance;
    final balanceHistory = orderedKeys.map((k) {
      runningBalance += periodNet[k] ?? 0;
      return AccountBalancePoint(
        date: keyToDate[k]!,
        label: keyToLabel[k]!,
        balance: runningBalance,
      );
    }).toList();

    return AccountComparisonData(
      accountId: id,
      name: account.name,
      color: account.color,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balanceHistory: balanceHistory,
    );
  }).toList();
});
