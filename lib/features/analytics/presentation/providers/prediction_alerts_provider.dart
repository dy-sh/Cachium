import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/prediction_alert.dart';
import 'analytics_filter_provider.dart';
import 'income_expense_summary_provider.dart';

const _uuid = Uuid();

/// Generates predictive alerts based on spending patterns
final predictionAlertsProvider = Provider<List<PredictionAlert>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final summary = ref.watch(incomeExpenseSummaryProvider);
  final transactions = transactionsAsync.valueOrNull;

  if (transactions == null || transactions.isEmpty) {
    return [];
  }

  final alerts = <PredictionAlert>[];
  final now = DateTime.now();

  // Filter to current period expenses
  final periodExpenses = transactions.where((tx) {
    return tx.type == TransactionType.expense &&
        filter.dateRange.contains(tx.date);
  }).toList();

  if (periodExpenses.isEmpty) return [];

  // Calculate daily spending rate
  final daysElapsed = now.difference(filter.dateRange.start).inDays + 1;
  final totalSpent = periodExpenses.fold<double>(0, (sum, tx) => sum + tx.amount);
  final dailyRate = totalSpent / daysElapsed;

  // Calculate days remaining in period
  final daysRemaining = filter.dateRange.end.difference(now).inDays;
  final daysInPeriod = filter.dateRange.dayCount;

  // Spending pace prediction
  if (daysElapsed >= 7 && daysRemaining > 0) {
    final projectedTotal = totalSpent + (dailyRate * daysRemaining);

    // Compare to previous period
    final previousStart = filter.dateRange.start.subtract(Duration(days: daysInPeriod));
    final previousEnd = filter.dateRange.start.subtract(const Duration(days: 1));
    final previousExpenses = transactions.where((tx) {
      return tx.type == TransactionType.expense &&
          tx.date.isAfter(previousStart) &&
          tx.date.isBefore(previousEnd.add(const Duration(days: 1)));
    }).toList();

    final previousTotal = previousExpenses.fold<double>(0, (sum, tx) => sum + tx.amount);

    if (previousTotal > 0) {
      final projectedVsPrevious = ((projectedTotal / previousTotal) - 1) * 100;

      if (projectedVsPrevious > 20) {
        alerts.add(PredictionAlert(
          id: _uuid.v4(),
          type: PredictionType.spendingPace,
          sentiment: PredictionSentiment.warning,
          title: 'Spending Pace Alert',
          message: 'On track to spend ${projectedVsPrevious.toStringAsFixed(0)}% more than last period',
          projectedAmount: projectedTotal,
          targetAmount: previousTotal,
        ));
      } else if (projectedVsPrevious < -10) {
        alerts.add(PredictionAlert(
          id: _uuid.v4(),
          type: PredictionType.spendingPace,
          sentiment: PredictionSentiment.positive,
          title: 'Good Spending Pace',
          message: 'On track to spend ${projectedVsPrevious.abs().toStringAsFixed(0)}% less than last period',
          projectedAmount: projectedTotal,
          targetAmount: previousTotal,
        ));
      }
    }
  }

  // Savings projection
  if (summary.totalIncome > 0 && daysRemaining > 0) {
    final projectedExpense = summary.totalExpense + (dailyRate * daysRemaining);
    final projectedSavings = summary.totalIncome - projectedExpense;
    final projectedSavingsRate = (projectedSavings / summary.totalIncome) * 100;

    if (projectedSavingsRate > 20) {
      alerts.add(PredictionAlert(
        id: _uuid.v4(),
        type: PredictionType.savingsProjection,
        sentiment: PredictionSentiment.positive,
        title: 'Great Savings Forecast',
        message: 'Projected ${projectedSavingsRate.toStringAsFixed(0)}% savings rate this period',
        projectedAmount: projectedSavings,
      ));
    } else if (projectedSavings < 0) {
      alerts.add(PredictionAlert(
        id: _uuid.v4(),
        type: PredictionType.savingsProjection,
        sentiment: PredictionSentiment.negative,
        title: 'Savings Warning',
        message: 'Projected to overspend by \$${projectedSavings.abs().toStringAsFixed(0)}',
        projectedAmount: projectedSavings,
      ));
    }
  }

  // Weekend spending pattern
  final weekendSpending = periodExpenses.where((tx) {
    final weekday = tx.date.weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }).fold<double>(0, (sum, tx) => sum + tx.amount);

  final weekdaySpending = totalSpent - weekendSpending;

  // Count weekend and weekday days elapsed
  int weekendDays = 0;
  int weekdayDays = 0;
  var date = filter.dateRange.start;
  while (!date.isAfter(now)) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      weekendDays++;
    } else {
      weekdayDays++;
    }
    date = date.add(const Duration(days: 1));
  }

  if (weekendDays >= 2 && weekdayDays >= 5) {
    final weekendDaily = weekendSpending / weekendDays;
    final weekdayDaily = weekdaySpending / weekdayDays;

    if (weekendDaily > weekdayDaily * 1.5) {
      final percentMore = ((weekendDaily / weekdayDaily) - 1) * 100;
      alerts.add(PredictionAlert(
        id: _uuid.v4(),
        type: PredictionType.spendingPace,
        sentiment: PredictionSentiment.warning,
        title: 'Weekend Spending Pattern',
        message: 'You spend ${percentMore.toStringAsFixed(0)}% more on weekends',
        projectedAmount: weekendDaily,
        targetAmount: weekdayDaily,
      ));
    }
  }

  return alerts.take(5).toList();
});
