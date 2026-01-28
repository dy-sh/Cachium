import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/financial_insight.dart';
import 'income_expense_summary_provider.dart';
import 'spending_trends_provider.dart';
import 'recurring_detection_provider.dart';
import 'spending_forecast_provider.dart';
import 'spending_patterns_provider.dart';
import 'category_breakdown_provider.dart';

final financialInsightsProvider = Provider<List<FinancialInsight>>((ref) {
  final summary = ref.watch(incomeExpenseSummaryProvider);
  final trend = ref.watch(spendingTrendsProvider);
  final recurringInsights = ref.watch(recurringDetectionProvider);
  final forecastInsights = ref.watch(spendingForecastProvider);
  final patternInsights = ref.watch(spendingPatternInsightsProvider);
  final breakdowns = ref.watch(categoryBreakdownProvider);

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
        priority: InsightPriority.high,
        value: savingsRate,
      ));
    } else if (savingsRate < 0) {
      insights.add(FinancialInsight(
        message: 'Spending exceeds income by ${(-summary.netAmount).toStringAsFixed(0)}',
        type: InsightType.spending,
        sentiment: InsightSentiment.negative,
        icon: LucideIcons.alertTriangle,
        priority: InsightPriority.high,
        value: summary.netAmount,
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
        priority: InsightPriority.high,
        value: trend.expenseChangePercent,
      ));
    } else if (trend.expenseChangePercent < -20) {
      insights.add(FinancialInsight(
        message: 'Expenses down ${trend.expenseChangePercent.abs().toStringAsFixed(0)}% vs previous period',
        type: InsightType.trend,
        sentiment: InsightSentiment.positive,
        icon: LucideIcons.trendingDown,
        priority: InsightPriority.medium,
        value: trend.expenseChangePercent,
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
        priority: InsightPriority.medium,
        value: trend.incomeChangePercent,
      ));
    } else if (trend.incomeChangePercent < -20) {
      insights.add(FinancialInsight(
        message: 'Income down ${trend.incomeChangePercent.abs().toStringAsFixed(0)}% vs previous period',
        type: InsightType.trend,
        sentiment: InsightSentiment.negative,
        icon: LucideIcons.trendingDown,
        priority: InsightPriority.high,
        value: trend.incomeChangePercent,
      ));
    }
  }

  // 4. Category anomaly insights (enhanced)
  for (final cat in trend.topCategoryChanges) {
    if (cat.changePercent.abs() > 50 && cat.currentAmount > 0) {
      final direction = cat.isIncrease ? 'increased' : 'decreased';
      final priority = cat.changePercent.abs() > 100
          ? InsightPriority.high
          : InsightPriority.medium;
      insights.add(FinancialInsight(
        message: '${cat.categoryName} $direction ${cat.changePercent.abs().toStringAsFixed(0)}%',
        type: InsightType.anomaly,
        sentiment: cat.isIncrease ? InsightSentiment.negative : InsightSentiment.positive,
        icon: cat.isIncrease ? LucideIcons.arrowUpCircle : LucideIcons.arrowDownCircle,
        priority: priority,
        value: cat.changePercent,
        categoryId: cat.categoryId,
      ));
    }
    if (insights.length >= 8) break;
  }

  // 5. Unusual single transaction detection (> 3x category average)
  if (breakdowns.length >= 2) {
    for (final b in breakdowns) {
      if (b.transactionCount >= 3) {
        final avgPerTx = b.amount / b.transactionCount;
        // Check if any single transaction would be > 3x the category average
        // We approximate: if the max possible single tx > 3x avg, the top amount dominates
        final maxPossibleSingle = b.amount - (avgPerTx * (b.transactionCount - 1));
        if (maxPossibleSingle > avgPerTx * 3) {
          insights.add(FinancialInsight(
            message: 'Unusual transaction detected in ${b.name}',
            type: InsightType.anomaly,
            sentiment: InsightSentiment.negative,
            icon: LucideIcons.alertOctagon,
            priority: InsightPriority.high,
            categoryId: b.categoryId,
          ));
          break;
        }
      }
    }
  }

  // 6. New category alert (categories with only 1 transaction)
  for (final b in breakdowns) {
    if (b.transactionCount == 1) {
      insights.add(FinancialInsight(
        message: 'First transaction in ${b.name} this period',
        type: InsightType.anomaly,
        sentiment: InsightSentiment.neutral,
        icon: LucideIcons.sparkles,
        priority: InsightPriority.low,
        categoryId: b.categoryId,
      ));
      break;
    }
  }

  // 7. Daily spending insight
  if (summary.averageDailyExpense > 0 && summary.dayCount >= 7) {
    insights.add(FinancialInsight(
      message: 'Averaging ${summary.averageDailyExpense.toStringAsFixed(0)}/day in expenses',
      type: InsightType.spending,
      sentiment: InsightSentiment.neutral,
      icon: LucideIcons.calendar,
      priority: InsightPriority.low,
      value: summary.averageDailyExpense,
    ));
  }

  // Merge in insights from other providers
  insights.addAll(recurringInsights);
  insights.addAll(forecastInsights);
  insights.addAll(patternInsights);

  // Sort by priority (high first)
  insights.sort((a, b) {
    final priorityOrder = {
      InsightPriority.high: 0,
      InsightPriority.medium: 1,
      InsightPriority.low: 2,
    };
    return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
  });

  return insights.take(8).toList();
});
