import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/date_range_preset.dart';
import '../../data/models/income_expense_summary.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import 'analytics_filter_provider.dart';
import 'filtered_transactions_provider.dart';

/// Previous-period transactions filtered with the same account/category
/// constraints as the current analytics filter, but shifted to the prior
/// period. Separated to avoid watching `transactionsProvider` directly
/// (which would cause cascade rebuilds of 40+ downstream providers).
final _previousPeriodTransactionsProvider = Provider<List<Transaction>>((ref) {
  ref.keepAlive();

  final filter = ref.watch(analyticsFilterProvider);

  // Read the full transaction list using .select() to only rebuild when
  // the resolved list changes, not on every AsyncValue state transition.
  final allTransactions = ref.watch(
    transactionsProvider.select((asyncValue) => asyncValue.valueOrNull),
  );
  if (allTransactions == null) return [];

  final currentRange = filter.dateRange;
  final dayCount = currentRange.dayCount;
  final previousEnd = currentRange.start.subtract(const Duration(days: 1));
  final previousStart = previousEnd.subtract(Duration(days: dayCount - 1));
  final previousRange = DateRange(
    start: DateTime(previousStart.year, previousStart.month, previousStart.day),
    end: DateTime(previousEnd.year, previousEnd.month, previousEnd.day, 23, 59, 59),
  );

  return allTransactions.where((tx) {
    if (!previousRange.contains(tx.date)) return false;
    if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) return false;
    if (filter.hasCategoryFilter && !filter.selectedCategoryIds.contains(tx.categoryId)) return false;
    return true;
  }).toList();
});

final incomeExpenseSummaryProvider = Provider<IncomeExpenseSummary>((ref) {
  // Keep alive to cache summary across analytics tab switches.
  ref.keepAlive();

  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final mainCurrency = ref.watch(mainCurrencyCodeProvider);
  // Use .select() to only rebuild when the resolved rates map changes,
  // not on every AsyncValue state transition.
  final rates = ref.watch(
    exchangeRatesProvider.select((v) => v.valueOrNull),
  ) ?? {};

  double totalIncome = 0;
  double totalExpense = 0;
  int incomeCount = 0;
  int expenseCount = 0;

  for (final tx in transactions) {
    if (tx.type == TransactionType.income) {
      totalIncome += convertedAmount(tx, rates, mainCurrency);
      incomeCount++;
    } else {
      totalExpense += convertedAmount(tx, rates, mainCurrency);
      expenseCount++;
    }
  }

  // Compute previous period from dedicated provider
  double previousTotalIncome = 0;
  double previousTotalExpense = 0;

  final previousTransactions = ref.watch(_previousPeriodTransactionsProvider);
  for (final tx in previousTransactions) {
    if (tx.type == TransactionType.income) {
      previousTotalIncome += convertedAmount(tx, rates, mainCurrency);
    } else {
      previousTotalExpense += convertedAmount(tx, rates, mainCurrency);
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
  // Keep alive to cache period summaries across tab switches.
  ref.keepAlive();

  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final mainCurrency = ref.watch(mainCurrencyCodeProvider);
  final rates = ref.watch(
    exchangeRatesProvider.select((v) => v.valueOrNull),
  ) ?? {};

  if (transactions.isEmpty) return [];

  final dayCount = filter.dateRange.dayCount;

  // Determine grouping
  if (dayCount <= 14) {
    return _groupByDay(transactions, filter.dateRange.start, filter.dateRange.end, rates, mainCurrency);
  } else if (dayCount <= 90) {
    return _groupByWeek(transactions, filter.dateRange.start, filter.dateRange.end, rates, mainCurrency);
  } else {
    return _groupByMonth(transactions, filter.dateRange.start, filter.dateRange.end, rates, mainCurrency);
  }
});

void _addTransaction(Map<dynamic, PeriodSummary> periods, dynamic key, Transaction tx, Map<String, double> rates, String mainCurrency) {
  final existing = periods[key];
  if (existing == null) return;
  if (tx.type == TransactionType.income) {
    periods[key] = existing.copyWith(income: existing.income + convertedAmount(tx, rates, mainCurrency));
  } else {
    periods[key] = existing.copyWith(expense: existing.expense + convertedAmount(tx, rates, mainCurrency));
  }
}

List<PeriodSummary> _groupByDay(
  List<Transaction> transactions,
  DateTime start,
  DateTime end,
  Map<String, double> rates,
  String mainCurrency,
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
    _addTransaction(periods, key, tx, rates, mainCurrency);
  }

  final result = periods.values.toList();
  result.sort((a, b) => a.periodStart.compareTo(b.periodStart));
  return result;
}

List<PeriodSummary> _groupByWeek(
  List<Transaction> transactions,
  DateTime start,
  DateTime end,
  Map<String, double> rates,
  String mainCurrency,
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
        _addTransaction(periods, entry.key, tx, rates, mainCurrency);
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
  Map<String, double> rates,
  String mainCurrency,
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
    _addTransaction(periods, key, tx, rates, mainCurrency);
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
