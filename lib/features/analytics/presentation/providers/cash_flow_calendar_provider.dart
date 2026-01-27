import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/calendar_day_data.dart';
import 'analytics_filter_provider.dart';

// Month offset for calendar navigation (0 = current filter month)
final calendarMonthOffsetProvider = StateProvider<int>((ref) => 0);

final cashFlowCalendarProvider = Provider<List<CalendarDayData>>((ref) {
  final filter = ref.watch(analyticsFilterProvider);
  final monthOffset = ref.watch(calendarMonthOffsetProvider);
  final transactionsAsync = ref.watch(transactionsProvider);

  final allTransactions = transactionsAsync.valueOrNull;
  if (allTransactions == null) return [];

  // Determine the month to display
  final baseEnd = filter.dateRange.end;
  final targetMonth = DateTime(baseEnd.year, baseEnd.month + monthOffset, 1);
  final start = targetMonth;
  final end = DateTime(targetMonth.year, targetMonth.month + 1, 0); // last day

  // Filter transactions to the target month (respecting account/category filters)
  final transactions = allTransactions.where((tx) {
    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (txDate.isBefore(start) || txDate.isAfter(end)) return false;
    if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) return false;
    if (filter.hasCategoryFilter && !filter.selectedCategoryIds.contains(tx.categoryId)) return false;
    return true;
  }).toList();

  // Group transactions by day
  final Map<String, double> incomeByDay = {};
  final Map<String, double> expenseByDay = {};

  for (final tx in transactions) {
    final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
    if (tx.type == TransactionType.income) {
      incomeByDay[key] = (incomeByDay[key] ?? 0) + tx.amount;
    } else {
      expenseByDay[key] = (expenseByDay[key] ?? 0) + tx.amount;
    }
  }

  // Build day list
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
      intensity: 0, // Will be recalculated
    ));
  }

  if (netValues.isEmpty) return days;

  // Assign intensity via quartiles
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

// Current displayed month for the calendar header
final calendarDisplayMonthProvider = Provider<DateTime>((ref) {
  final filter = ref.watch(analyticsFilterProvider);
  final offset = ref.watch(calendarMonthOffsetProvider);
  final baseEnd = filter.dateRange.end;
  return DateTime(baseEnd.year, baseEnd.month + offset, 1);
});
