import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_forecast.dart';
import 'analytics_filter_provider.dart';
import 'category_breakdown_provider.dart';
import 'income_expense_summary_provider.dart';

final budgetForecastProvider = Provider<List<BudgetForecast>>((ref) {
  final breakdowns = ref.watch(categoryBreakdownProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final summary = ref.watch(incomeExpenseSummaryProvider);

  if (breakdowns.isEmpty) return [];

  final dateRange = filter.dateRange;
  final now = DateTime.now();
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  final daysSoFar = now.difference(dateRange.start).inDays + 1;
  final daysRemaining = endOfMonth.difference(now).inDays;

  if (daysSoFar <= 0) return [];

  final forecasts = <BudgetForecast>[];

  for (final breakdown in breakdowns) {
    final dailyRate = breakdown.amount / daysSoFar;
    final totalDaysInMonth = daysSoFar + daysRemaining;
    final projectedSpending = dailyRate * totalDaysInMonth;

    // Use previous period spending as budget baseline
    // Approximate from summary's previous expense proportionally
    final budgetAmount = summary.previousTotalExpense > 0
        ? summary.previousTotalExpense * breakdown.percentage / 100
        : breakdown.amount;

    final overage = projectedSpending - budgetAmount;

    forecasts.add(BudgetForecast(
      categoryId: breakdown.categoryId,
      categoryName: breakdown.name,
      categoryColor: breakdown.color,
      currentSpending: breakdown.amount,
      projectedSpending: projectedSpending,
      budgetAmount: budgetAmount,
      overage: overage,
      dailyRate: dailyRate,
      daysRemaining: daysRemaining,
    ));
  }

  // Sort by overage descending
  forecasts.sort((a, b) => b.overage.compareTo(a.overage));

  return forecasts;
});
