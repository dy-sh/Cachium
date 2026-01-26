import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/income_expense_summary.dart';
import 'analytics_filter_provider.dart';
import 'filtered_transactions_provider.dart';

final incomeExpenseSummaryProvider = Provider<IncomeExpenseSummary>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);

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

  return IncomeExpenseSummary(
    periodStart: filter.dateRange.start,
    periodEnd: filter.dateRange.end,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    incomeCount: incomeCount,
    expenseCount: expenseCount,
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

    final existing = periods[key];
    if (existing != null) {
      if (tx.type == TransactionType.income) {
        periods[key] = PeriodSummary(
          periodStart: existing.periodStart,
          periodEnd: existing.periodEnd,
          label: existing.label,
          income: existing.income + tx.amount,
          expense: existing.expense,
        );
      } else {
        periods[key] = PeriodSummary(
          periodStart: existing.periodStart,
          periodEnd: existing.periodEnd,
          label: existing.label,
          income: existing.income,
          expense: existing.expense + tx.amount,
        );
      }
    }
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
    // Find which week this transaction belongs to
    for (final entry in periods.entries) {
      final period = entry.value;
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (!txDate.isBefore(period.periodStart) &&
          !txDate.isAfter(period.periodEnd)) {
        if (tx.type == TransactionType.income) {
          periods[entry.key] = PeriodSummary(
            periodStart: period.periodStart,
            periodEnd: period.periodEnd,
            label: period.label,
            income: period.income + tx.amount,
            expense: period.expense,
          );
        } else {
          periods[entry.key] = PeriodSummary(
            periodStart: period.periodStart,
            periodEnd: period.periodEnd,
            label: period.label,
            income: period.income,
            expense: period.expense + tx.amount,
          );
        }
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

    final existing = periods[key];
    if (existing != null) {
      if (tx.type == TransactionType.income) {
        periods[key] = PeriodSummary(
          periodStart: existing.periodStart,
          periodEnd: existing.periodEnd,
          label: existing.label,
          income: existing.income + tx.amount,
          expense: existing.expense,
        );
      } else {
        periods[key] = PeriodSummary(
          periodStart: existing.periodStart,
          periodEnd: existing.periodEnd,
          label: existing.label,
          income: existing.income,
          expense: existing.expense + tx.amount,
        );
      }
    }
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
