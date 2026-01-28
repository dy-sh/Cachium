import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/financial_insight.dart';
import 'income_expense_summary_provider.dart';

final spendingForecastProvider = Provider<List<FinancialInsight>>((ref) {
  final summary = ref.watch(incomeExpenseSummaryProvider);
  final insights = <FinancialInsight>[];

  if (summary.dayCount < 3 || summary.totalExpense == 0) return insights;

  final now = DateTime.now();
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  final daysLeft = endOfMonth.difference(now).inDays;

  if (daysLeft <= 0) return insights;

  final dailyRate = summary.averageDailyExpense;
  final projected = summary.totalExpense + (dailyRate * daysLeft);

  // Compare to previous period expense
  if (summary.previousTotalExpense > 0) {
    final changePercent = ((projected - summary.previousTotalExpense) / summary.previousTotalExpense * 100);

    if (changePercent > 10) {
      insights.add(FinancialInsight(
        message: 'On track to spend ${changePercent.toStringAsFixed(0)}% more than last period',
        type: InsightType.forecast,
        sentiment: InsightSentiment.negative,
        icon: LucideIcons.trendingUp,
        priority: InsightPriority.high,
        value: projected,
      ));
    } else if (changePercent < -10) {
      insights.add(FinancialInsight(
        message: 'Projected to spend ${changePercent.abs().toStringAsFixed(0)}% less than last period',
        type: InsightType.forecast,
        sentiment: InsightSentiment.positive,
        icon: LucideIcons.trendingDown,
        priority: InsightPriority.medium,
        value: projected,
      ));
    }
  }

  // Daily rate insight
  insights.add(FinancialInsight(
    message: 'Projected month-end expenses: ${projected.toStringAsFixed(0)}',
    type: InsightType.forecast,
    sentiment: InsightSentiment.neutral,
    icon: LucideIcons.target,
    priority: InsightPriority.low,
    value: projected,
  ));

  return insights;
});
