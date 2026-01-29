import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../data/models/financial_health.dart';
import 'income_expense_summary_provider.dart';
import 'net_worth_history_provider.dart';

final financialHealthProvider = Provider<FinancialHealth>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final summary = ref.watch(incomeExpenseSummaryProvider);
  final netWorthHistory = ref.watch(netWorthHistoryProvider);

  final accounts = accountsAsync.valueOrNull;
  if (accounts == null || accounts.isEmpty) {
    return FinancialHealth.empty;
  }

  // Calculate current totals using AccountType classification
  double totalAssets = 0;
  double totalLiabilities = 0;
  double liquidAssets = 0;

  for (final account in accounts) {
    if (account.type.isLiability) {
      totalLiabilities += account.balance.abs();
    } else {
      totalAssets += account.balance;
      if (account.type.isLiquid) {
        liquidAssets += account.balance;
      }
    }
  }

  // 1. Debt-to-Asset Ratio (25 points)
  // Lower is better: 0% = 25pts, 50% = 12.5pts, 100%+ = 0pts
  final debtRatio = totalAssets > 0 ? (totalLiabilities / totalAssets) : 0.0;
  final debtRatioScore = ((1 - (debtRatio.clamp(0.0, 1.0))) * 25).round();

  // 2. Savings Rate (25 points)
  // Higher is better: 0% = 0pts, 20% = 25pts
  final savingsRate = summary.savingsRate;
  final savingsRateScore = ((savingsRate.clamp(0.0, 20.0) / 20.0) * 25).round();

  // 3. Emergency Fund (25 points)
  // Calculate months of expenses covered by liquid assets
  // Uses monthly average expense from current period
  final daysInPeriod = summary.periodEnd.difference(summary.periodStart).inDays + 1;
  final dailyExpense = daysInPeriod > 0 ? summary.totalExpense / daysInPeriod : 0.0;
  final monthlyExpense = dailyExpense * 30;
  final emergencyMonths = monthlyExpense > 0 ? liquidAssets / monthlyExpense : 0.0;
  // 6 months = full score
  final emergencyScore = ((emergencyMonths.clamp(0.0, 6.0) / 6.0) * 25).round();

  // 4. Net Worth Trend (25 points)
  // Positive trend = full score, negative trend = reduced score
  double netWorthTrend = 0;
  int trendScore = 0;

  if (netWorthHistory.length >= 2) {
    final firstNetWorth = netWorthHistory.first.netWorth;
    final lastNetWorth = netWorthHistory.last.netWorth;

    if (firstNetWorth != 0) {
      netWorthTrend = ((lastNetWorth - firstNetWorth) / firstNetWorth.abs()) * 100;
    } else if (lastNetWorth > 0) {
      netWorthTrend = 100;
    }

    // +10% or more = 25pts, 0% = 12.5pts, -10% or less = 0pts
    final normalizedTrend = (netWorthTrend + 10) / 20; // -10 to +10 -> 0 to 1
    trendScore = (normalizedTrend.clamp(0.0, 1.0) * 25).round();
  } else {
    // No history, neutral score
    trendScore = 12;
  }

  final healthScore = (debtRatioScore + savingsRateScore + emergencyScore + trendScore).clamp(0, 100);

  return FinancialHealth(
    debtToAssetRatio: debtRatio * 100,
    savingsRate: savingsRate,
    emergencyFundMonths: emergencyMonths,
    netWorthTrend: netWorthTrend,
    healthScore: healthScore,
  );
});
