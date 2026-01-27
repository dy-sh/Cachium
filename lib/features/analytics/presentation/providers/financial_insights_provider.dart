import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/financial_insight.dart';
import 'income_expense_summary_provider.dart';
import 'spending_trends_provider.dart';

final financialInsightsProvider = Provider<List<FinancialInsight>>((ref) {
  final summary = ref.watch(incomeExpenseSummaryProvider);
  final trend = ref.watch(spendingTrendsProvider);

  final insights = <FinancialInsight>[];

  // 1. Savings rate insight
  if (summary.totalIncome > 0) {
    final savingsRate = summary.savingsRate;
    if (savingsRate > 20) {
      insights.add(FinancialInsight(
        message: 'Great savings rate of ${savingsRate.toStringAsFixed(0)}% this period',
        type: InsightType.saving,
        sentiment: InsightSentiment.positive,
        icon: LucideIcons.piggyBank,
      ));
    } else if (savingsRate < 0) {
      insights.add(FinancialInsight(
        message: 'Spending exceeds income by ${(-summary.netAmount).toStringAsFixed(0)}',
        type: InsightType.spending,
        sentiment: InsightSentiment.negative,
        icon: LucideIcons.alertTriangle,
      ));
    }
  }

  // 2. Expense trend insight
  if (trend.hasData && trend.previousExpense > 0) {
    if (trend.expenseChangePercent > 20) {
      insights.add(FinancialInsight(
        message: 'Expenses up ${trend.expenseChangePercent.toStringAsFixed(0)}% vs previous period',
        type: InsightType.trend,
        sentiment: InsightSentiment.negative,
        icon: LucideIcons.trendingUp,
      ));
    } else if (trend.expenseChangePercent < -20) {
      insights.add(FinancialInsight(
        message: 'Expenses down ${trend.expenseChangePercent.abs().toStringAsFixed(0)}% vs previous period',
        type: InsightType.trend,
        sentiment: InsightSentiment.positive,
        icon: LucideIcons.trendingDown,
      ));
    }
  }

  // 3. Income trend insight
  if (trend.hasData && trend.previousIncome > 0) {
    if (trend.incomeChangePercent > 20) {
      insights.add(FinancialInsight(
        message: 'Income up ${trend.incomeChangePercent.toStringAsFixed(0)}% vs previous period',
        type: InsightType.trend,
        sentiment: InsightSentiment.positive,
        icon: LucideIcons.trendingUp,
      ));
    } else if (trend.incomeChangePercent < -20) {
      insights.add(FinancialInsight(
        message: 'Income down ${trend.incomeChangePercent.abs().toStringAsFixed(0)}% vs previous period',
        type: InsightType.trend,
        sentiment: InsightSentiment.negative,
        icon: LucideIcons.trendingDown,
      ));
    }
  }

  // 4. Category anomaly insights
  for (final cat in trend.topCategoryChanges) {
    if (cat.changePercent.abs() > 50 && cat.currentAmount > 0) {
      final direction = cat.isIncrease ? 'increased' : 'decreased';
      insights.add(FinancialInsight(
        message: '${cat.categoryName} $direction ${cat.changePercent.abs().toStringAsFixed(0)}%',
        type: InsightType.anomaly,
        sentiment: cat.isIncrease ? InsightSentiment.negative : InsightSentiment.positive,
        icon: cat.isIncrease ? LucideIcons.arrowUpCircle : LucideIcons.arrowDownCircle,
      ));
    }
    if (insights.length >= 5) break;
  }

  // 5. Daily spending insight
  if (summary.averageDailyExpense > 0 && summary.dayCount >= 7) {
    insights.add(FinancialInsight(
      message: 'Averaging ${summary.averageDailyExpense.toStringAsFixed(0)}/day in expenses',
      type: InsightType.spending,
      sentiment: InsightSentiment.neutral,
      icon: LucideIcons.calendar,
    ));
  }

  return insights.take(5).toList();
});
