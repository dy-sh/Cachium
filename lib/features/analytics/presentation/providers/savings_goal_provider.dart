import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/savings_goal.dart';
import 'income_expense_summary_provider.dart';

final savingsGoalTargetProvider = StateProvider<double>((ref) => 0);

final savingsGoalProvider = Provider<SavingsGoal?>((ref) {
  final target = ref.watch(savingsGoalTargetProvider);
  final summary = ref.watch(incomeExpenseSummaryProvider);

  if (target <= 0) return null;

  final currentSaved = summary.netAmount > 0 ? summary.netAmount : 0.0;
  final projectedMonthlySavings =
      summary.averageDailyNet > 0 ? summary.averageDailyNet * 30 : 0.0;

  final remaining = target - currentSaved;

  // Estimate completion date
  DateTime? estimatedCompletionDate;
  if (projectedMonthlySavings > 0 && remaining > 0) {
    final monthsNeeded = (remaining / projectedMonthlySavings).ceil();
    final now = DateTime.now();
    estimatedCompletionDate = DateTime(
      now.year,
      now.month + monthsNeeded,
      now.day,
    );
  } else if (remaining <= 0) {
    estimatedCompletionDate = DateTime.now();
  }

  // Build projected path: monthly points from now to completion
  final projectedPath = <SavingsGoalPoint>[];
  final now = DateTime.now();
  double accumulated = currentSaved;

  if (projectedMonthlySavings > 0 && remaining > 0) {
    final monthsNeeded = (remaining / projectedMonthlySavings).ceil();
    for (int i = 0; i <= monthsNeeded; i++) {
      final date = DateTime(now.year, now.month + i, now.day);
      projectedPath.add(SavingsGoalPoint(
        date: date,
        amount: accumulated.clamp(0, target),
      ));
      accumulated += projectedMonthlySavings;
    }
  } else {
    // Just add current point
    projectedPath.add(SavingsGoalPoint(
      date: now,
      amount: currentSaved.clamp(0, target),
    ));
  }

  return SavingsGoal(
    targetAmount: target,
    currentSaved: currentSaved,
    projectedMonthlySavings: projectedMonthlySavings,
    estimatedCompletionDate: estimatedCompletionDate,
    projectedPath: projectedPath,
  );
});
