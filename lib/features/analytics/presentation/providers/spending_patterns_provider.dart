import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/financial_insight.dart';
import 'filtered_transactions_provider.dart';

class DayOfWeekData {
  final int weekday; // 1=Mon, 7=Sun
  final String name;
  final double totalAmount;
  final int transactionCount;
  final double average;

  const DayOfWeekData({
    required this.weekday,
    required this.name,
    required this.totalAmount,
    required this.transactionCount,
    required this.average,
  });
}

final spendingPatternsProvider = Provider<List<DayOfWeekData>>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);

  final expenses = transactions.where((tx) => tx.type == TransactionType.expense).toList();
  if (expenses.isEmpty) return [];

  // Group by day of week
  final dayTotals = <int, double>{};
  final dayCounts = <int, int>{};

  for (final tx in expenses) {
    final day = tx.date.weekday;
    dayTotals[day] = (dayTotals[day] ?? 0) + tx.amount;
    dayCounts[day] = (dayCounts[day] ?? 0) + 1;
  }

  // Count unique weeks in the data
  final weeks = <String>{};
  for (final tx in expenses) {
    final weekStart = tx.date.subtract(Duration(days: tx.date.weekday - 1));
    weeks.add('${weekStart.year}-${weekStart.month}-${weekStart.day}');
  }
  final weekCount = weeks.length.clamp(1, 999);

  const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return List.generate(7, (i) {
    final day = i + 1;
    final total = dayTotals[day] ?? 0;
    return DayOfWeekData(
      weekday: day,
      name: dayNames[day],
      totalAmount: total,
      transactionCount: dayCounts[day] ?? 0,
      average: total / weekCount,
    );
  });
});

final spendingPatternInsightsProvider = Provider<List<FinancialInsight>>((ref) {
  final patterns = ref.watch(spendingPatternsProvider);
  if (patterns.isEmpty) return [];

  final insights = <FinancialInsight>[];

  // Find peak spending day
  final sorted = List<DayOfWeekData>.from(patterns)..sort((a, b) => b.average.compareTo(a.average));
  final peak = sorted.first;
  final overallAvg = patterns.fold(0.0, (s, d) => s + d.average) / 7;

  if (peak.average > overallAvg * 1.3 && peak.transactionCount >= 2) {
    insights.add(FinancialInsight(
      message: '${peak.name}s are your highest spending day (${peak.average.toStringAsFixed(0)} avg)',
      type: InsightType.pattern,
      sentiment: InsightSentiment.neutral,
      icon: LucideIcons.calendarDays,
      priority: InsightPriority.low,
    ));
  }

  // Weekend vs weekday
  final weekdayAvg = patterns.where((d) => d.weekday <= 5).fold(0.0, (s, d) => s + d.average) / 5;
  final weekendAvg = patterns.where((d) => d.weekday > 5).fold(0.0, (s, d) => s + d.average) / 2;

  if (weekendAvg > weekdayAvg * 1.5 && weekendAvg > 0) {
    insights.add(FinancialInsight(
      message: 'Weekend spending is ${((weekendAvg / weekdayAvg - 1) * 100).toStringAsFixed(0)}% higher than weekdays',
      type: InsightType.pattern,
      sentiment: InsightSentiment.neutral,
      icon: LucideIcons.calendarRange,
      priority: InsightPriority.low,
    ));
  }

  return insights;
});
