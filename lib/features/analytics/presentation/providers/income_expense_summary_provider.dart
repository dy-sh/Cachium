import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/date_range_preset.dart';
import '../../data/models/income_expense_summary.dart';
import 'analytics_filter_provider.dart';
import 'filtered_transactions_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

final incomeExpenseSummaryProvider = Provider<IncomeExpenseSummary>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final allTransactionsAsync = ref.watch(transactionsProvider);

  double totalIncome = 0;
  double totalExpense = 0;
  int incomeCount = 0;
  int expenseCount = 0;

  for (final tx in transactions) {
    if (tx.type == TransactionType.income) {
      totalIncome += tx.amount;
      incomeCount++;
    } else {
      totalExpense += tx.amount;
      expenseCount++;
    }
  }

  // Compute previous period
  double previousTotalIncome = 0;
  double previousTotalExpense = 0;

  final allTransactions = allTransactionsAsync.valueOrNull;
  if (allTransactions != null) {
    final currentRange = filter.dateRange;
    final dayCount = currentRange.dayCount;
    final previousEnd = currentRange.start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: dayCount - 1));
    final previousRange = DateRange(
      start: DateTime(previousStart.year, previousStart.month, previousStart.day),
      end: DateTime(previousEnd.year, previousEnd.month, previousEnd.day, 23, 59, 59),
    );

    for (final tx in allTransactions) {
      if (!previousRange.contains(tx.date)) continue;
      if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) continue;
      if (filter.hasCategoryFilter && !filter.selectedCategoryIds.contains(tx.categoryId)) continue;

      if (tx.type == TransactionType.income) {
        previousTotalIncome += tx.amount;
      } else {
        previousTotalExpense += tx.amount;
      }
    }
  }

  return IncomeExpenseSummary(
    periodStart: filter.dateRange.start,
    periodEnd: filter.dateRange.end,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    incomeCount: incomeCount,
    expenseCount: expenseCount,
    previousTotalIncome: previousTotalIncome,
    previousTotalExpense: previousTotalExpense,
  );
});

// Period summaries for bar chart (grouped by week/month depending on range)
final periodSummariesProvider = Provider<List<PeriodSummary>>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);

  if (transactions.isEmpty) return [];

  final dayCount = filter.dateRange.dayCount;

  // Determine grouping
  if (dayCount <= 14) {
    return _groupByDay(transactions, filter.dateRange.start, filter.dateRange.end);
  } else if (dayCount <= 90) {
    return _groupByWeek(transactions, filter.dateRange.start, filter.dateRange.end);
  } else {
    return _groupByMonth(transactions, filter.dateRange.start, filter.dateRange.end);
  }
});

void _addTransaction(Map<dynamic, PeriodSummary> periods, dynamic key, Transaction tx) {
  final existing = periods[key];
  if (existing == null) return;
  if (tx.type == TransactionType.income) {
    periods[key] = existing.copyWith(income: existing.income + tx.amount);
  } else {
    periods[key] = existing.copyWith(expense: existing.expense + tx.amount);
  }
}

List<PeriodSummary> _groupByDay(
  List<Transaction> transactions,
  DateTime start,
  DateTime end,
) {
  final Map<String, PeriodSummary> periods = {};

  var currentDate = DateTime(start.year, start.month, start.day);
  final endDate = DateTime(end.year, end.month, end.day);

  while (!currentDate.isAfter(endDate)) {
    final key = '${currentDate.month}/${currentDate.day}';
    periods[key] = PeriodSummary(
      periodStart: currentDate,
      periodEnd: currentDate,
      label: key,
      income: 0,
      expense: 0,
    );
    currentDate = currentDate.add(const Duration(days: 1));
  }

  for (final tx in transactions) {
    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
    final key = '${txDate.month}/${txDate.day}';
    _addTransaction(periods, key, tx);
  }

  final result = periods.values.toList();
  result.sort((a, b) => a.periodStart.compareTo(b.periodStart));
  return result;
}

List<PeriodSummary> _groupByWeek(
  List<Transaction> transactions,
  DateTime start,
  DateTime end,
) {
  final Map<int, PeriodSummary> periods = {};

  var currentDate = DateTime(start.year, start.month, start.day);
  final endDate = DateTime(end.year, end.month, end.day);

  // Find start of first week
  while (currentDate.weekday != DateTime.monday) {
    currentDate = currentDate.subtract(const Duration(days: 1));
  }

  int weekIndex = 0;
  while (!currentDate.isAfter(endDate)) {
    final weekEnd = currentDate.add(const Duration(days: 6));
    final label = '${currentDate.month}/${currentDate.day}';

    periods[weekIndex] = PeriodSummary(
      periodStart: currentDate,
      periodEnd: weekEnd,
      label: label,
      income: 0,
      expense: 0,
    );

    currentDate = currentDate.add(const Duration(days: 7));
    weekIndex++;
  }

  for (final tx in transactions) {
    for (final entry in periods.entries) {
      final period = entry.value;
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (!txDate.isBefore(period.periodStart) &&
          !txDate.isAfter(period.periodEnd)) {
        _addTransaction(periods, entry.key, tx);
        break;
      }
    }
  }

  final result = periods.values.toList();
  result.sort((a, b) => a.periodStart.compareTo(b.periodStart));
  return result;
}

List<PeriodSummary> _groupByMonth(
  List<Transaction> transactions,
  DateTime start,
  DateTime end,
) {
  final Map<String, PeriodSummary> periods = {};

  var currentMonth = DateTime(start.year, start.month, 1);
  final endMonth = DateTime(end.year, end.month, 1);

  while (!currentMonth.isAfter(endMonth)) {
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));

    final key = '${currentMonth.year}-${currentMonth.month}';
    final label = _getMonthLabel(currentMonth.month);

    periods[key] = PeriodSummary(
      periodStart: currentMonth,
      periodEnd: lastDay,
      label: label,
      income: 0,
      expense: 0,
    );

    currentMonth = nextMonth;
  }

  for (final tx in transactions) {
    final key = '${tx.date.year}-${tx.date.month}';
    _addTransaction(periods, key, tx);
  }

  final result = periods.values.toList();
  result.sort((a, b) => a.periodStart.compareTo(b.periodStart));
  return result;
}

String _getMonthLabel(int month) {
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month];
}
