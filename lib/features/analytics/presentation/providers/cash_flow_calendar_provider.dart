import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/calendar_day_data.dart';
import 'analytics_filter_provider.dart';
import 'filtered_transactions_provider.dart';

final cashFlowCalendarProvider = Provider<List<CalendarDayData>>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);

  if (transactions.isEmpty) return [];

  final start = filter.dateRange.start;
  final end = filter.dateRange.end;

  // Cap at 3 months
  final cappedStart = end.difference(start).inDays > 92
      ? end.subtract(const Duration(days: 92))
      : start;

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
  final dayCount = end.difference(cappedStart).inDays + 1;

  final netValues = <double>[];

  for (int i = 0; i < dayCount; i++) {
    final date = cappedStart.add(Duration(days: i));
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
