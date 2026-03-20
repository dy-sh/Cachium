import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../bills/presentation/providers/bill_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/calendar_day_data.dart';

/// Month offset for standalone calendar screen (0 = current month)
final calendarScreenMonthOffsetProvider = StateProvider<int>((ref) => 0);

/// Display month derived from offset
final calendarScreenDisplayMonthProvider = Provider<DateTime>((ref) {
  final offset = ref.watch(calendarScreenMonthOffsetProvider);
  final now = DateTime.now();
  return DateTime(now.year, now.month + offset, 1);
});

/// Calendar data for all (non-deleted) transactions, independent of analytics filter
final calendarScreenDataProvider = Provider<List<CalendarDayData>>((ref) {
  final monthOffset = ref.watch(calendarScreenMonthOffsetProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  final mainCurrency = ref.watch(mainCurrencyCodeProvider);
  final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};

  final allTransactions = transactionsAsync.valueOrNull;
  if (allTransactions == null) return [];

  final now = DateTime.now();
  final targetMonth = DateTime(now.year, now.month + monthOffset, 1);
  final start = targetMonth;
  final end = DateTime(targetMonth.year, targetMonth.month + 1, 0);

  final transactions = allTransactions.where((tx) {
    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
    return !txDate.isBefore(start) && !txDate.isAfter(end);
  }).toList();

  final Map<String, double> incomeByDay = {};
  final Map<String, double> expenseByDay = {};

  for (final tx in transactions) {
    final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
    if (tx.type == TransactionType.income) {
      incomeByDay[key] = (incomeByDay[key] ?? 0) + convertedAmount(tx, rates, mainCurrency);
    } else if (tx.type == TransactionType.expense) {
      expenseByDay[key] = (expenseByDay[key] ?? 0) + convertedAmount(tx, rates, mainCurrency);
    }
  }

  final days = <CalendarDayData>[];
  final dayCount = end.difference(start).inDays + 1;
  final netValues = <double>[];

  for (int i = 0; i < dayCount; i++) {
    final date = start.add(Duration(days: i));
    final key = '${date.year}-${date.month}-${date.day}';
    final income = incomeByDay[key] ?? 0;
    final expense = expenseByDay[key] ?? 0;
    final net = income - expense;

    if (net != 0) netValues.add(net.abs());

    days.add(CalendarDayData(
      date: date,
      income: income,
      expense: expense,
      net: net,
      intensity: 0,
    ));
  }

  if (netValues.isEmpty) return days;

  netValues.sort();
  final q1 = netValues[(netValues.length * 0.25).floor()];
  final q2 = netValues[(netValues.length * 0.50).floor()];
  final q3 = netValues[(netValues.length * 0.75).floor()];

  return days.map((d) {
    final absNet = d.net.abs();
    int intensity;
    if (absNet == 0) {
      intensity = 0;
    } else if (absNet <= q1) {
      intensity = 1;
    } else if (absNet <= q2) {
      intensity = 2;
    } else if (absNet <= q3) {
      intensity = 3;
    } else {
      intensity = 4;
    }

    return CalendarDayData(
      date: d.date,
      income: d.income,
      expense: d.expense,
      net: d.net,
      intensity: intensity,
    );
  }).toList();
});

/// Selected day on the calendar screen
final calendarScreenSelectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Transactions for the selected day
final calendarDayTransactionsProvider = Provider<List<Transaction>>((ref) {
  final selectedDay = ref.watch(calendarScreenSelectedDayProvider);
  if (selectedDay == null) return [];

  final transactionsAsync = ref.watch(transactionsProvider);
  final allTransactions = transactionsAsync.valueOrNull;
  if (allTransactions == null) return [];

  return allTransactions.where((tx) {
    return tx.date.year == selectedDay.year &&
        tx.date.month == selectedDay.month &&
        tx.date.day == selectedDay.day;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

/// Set of date keys (yyyy-M-d) for unpaid bill due dates, for dot indicators
final calendarBillDatesProvider = Provider<Set<String>>((ref) {
  final bills = ref.watch(billsProvider).valueOrNull ?? [];
  return bills
      .where((b) => !b.isPaid)
      .map((b) => '${b.dueDate.year}-${b.dueDate.month}-${b.dueDate.day}')
      .toSet();
});
