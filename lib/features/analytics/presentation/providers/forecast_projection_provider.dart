import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/forecast_projection.dart';
import 'analytics_filter_provider.dart';
import 'filtered_transactions_provider.dart';

final forecastProjectionProvider = Provider<List<ForecastProjection>>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);

  if (transactions.isEmpty) return [];

  final dateRange = filter.dateRange;

  // Group transactions by day to compute daily net (income - expense)
  final Map<int, double> dailyNet = {};
  final startDay = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);

  for (final tx in transactions) {
    final dayOffset = DateTime(tx.date.year, tx.date.month, tx.date.day)
        .difference(startDay)
        .inDays;
    final amount = tx.type == TransactionType.income ? tx.amount : -tx.amount;
    dailyNet[dayOffset] = (dailyNet[dayOffset] ?? 0) + amount;
  }

  final totalDays = dateRange.end.difference(dateRange.start).inDays + 1;

  // Build actual daily values list
  final List<double> dailyValues = [];
  for (int i = 0; i < totalDays; i++) {
    dailyValues.add(dailyNet[i] ?? 0);
  }

  // Build actual projection points (cumulative)
  final List<ForecastProjection> results = [];
  double cumulative = 0;

  for (int i = 0; i < dailyValues.length; i++) {
    cumulative += dailyValues[i];
    final date = startDay.add(Duration(days: i));
    results.add(ForecastProjection(
      date: date,
      amount: cumulative,
      upperBound: cumulative,
      lowerBound: cumulative,
      isActual: true,
    ));
  }

  // Compute weighted moving average using last 14 days
  final windowSize = min(14, dailyValues.length);
  final recentValues = dailyValues.sublist(dailyValues.length - windowSize);

  double weightedSum = 0;
  double weightTotal = 0;
  for (int i = 0; i < recentValues.length; i++) {
    final weight = (i + 1).toDouble();
    weightedSum += recentValues[i] * weight;
    weightTotal += weight;
  }
  final weightedAvg = weightTotal > 0 ? weightedSum / weightTotal : 0.0;

  // Standard deviation of daily values
  final mean = dailyValues.fold(0.0, (sum, v) => sum + v) / dailyValues.length;
  final variance = dailyValues.fold(0.0, (sum, v) => sum + pow(v - mean, 2)) /
      dailyValues.length;
  final stdDev = sqrt(variance);

  // Extrapolate forward 30 days
  for (int i = 1; i <= 30; i++) {
    cumulative += weightedAvg;
    final date = dateRange.end.add(Duration(days: i));
    final band = stdDev * sqrt(i.toDouble());
    results.add(ForecastProjection(
      date: date,
      amount: cumulative,
      upperBound: cumulative + band,
      lowerBound: cumulative - band,
      isActual: false,
    ));
  }

  return results;
});
