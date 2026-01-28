import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/what_if_result.dart';
import 'category_breakdown_provider.dart';
import 'income_expense_summary_provider.dart';

class WhatIfAdjustmentsNotifier extends StateNotifier<List<WhatIfAdjustment>> {
  WhatIfAdjustmentsNotifier() : super([]);

  void setAdjustment(String categoryId, String categoryName, double percentChange) {
    final existing = state.indexWhere((a) => a.categoryId == categoryId);
    if (existing >= 0) {
      final updated = [...state];
      updated[existing] = WhatIfAdjustment(
        categoryId: categoryId,
        categoryName: categoryName,
        percentChange: percentChange,
      );
      state = updated;
    } else {
      state = [
        ...state,
        WhatIfAdjustment(
          categoryId: categoryId,
          categoryName: categoryName,
          percentChange: percentChange,
        ),
      ];
    }
  }

  void resetAll() {
    state = [];
  }

  void resetCategory(String categoryId) {
    state = state.where((a) => a.categoryId != categoryId).toList();
  }
}

final whatIfAdjustmentsProvider =
    StateNotifierProvider<WhatIfAdjustmentsNotifier, List<WhatIfAdjustment>>(
  (ref) => WhatIfAdjustmentsNotifier(),
);

final whatIfResultProvider = Provider<WhatIfResult>((ref) {
  final adjustments = ref.watch(whatIfAdjustmentsProvider);
  final summary = ref.watch(incomeExpenseSummaryProvider);
  final breakdowns = ref.watch(categoryBreakdownProvider);

  final dayCount = summary.dayCount > 0 ? summary.dayCount : 1;
  final baselineMonthlyIncome = summary.totalIncome / dayCount * 30;
  final baselineMonthlyExpense = summary.totalExpense / dayCount * 30;
  final baselineMonthlyNet = baselineMonthlyIncome - baselineMonthlyExpense;

  // Build adjustment map
  final adjustmentMap = <String, double>{};
  for (final adj in adjustments) {
    adjustmentMap[adj.categoryId] = adj.percentChange;
  }

  // Apply adjustments to each category's spending
  double projectedMonthlyExpense = 0;
  final categoryImpacts = <WhatIfCategoryImpact>[];

  for (final breakdown in breakdowns) {
    final monthlyAmount = breakdown.amount / dayCount * 30;
    final percentChange = adjustmentMap[breakdown.categoryId] ?? 0;
    final adjustedAmount = monthlyAmount * (1 + percentChange / 100);

    projectedMonthlyExpense += adjustedAmount;

    if (percentChange != 0) {
      categoryImpacts.add(WhatIfCategoryImpact(
        categoryId: breakdown.categoryId,
        categoryName: breakdown.name,
        originalAmount: monthlyAmount,
        adjustedAmount: adjustedAmount,
        percentChange: percentChange,
      ));
    }
  }

  // If no breakdowns matched, fall back to baseline
  if (breakdowns.isEmpty) {
    projectedMonthlyExpense = baselineMonthlyExpense;
  }

  final projectedMonthlyNet = baselineMonthlyIncome - projectedMonthlyExpense;

  return WhatIfResult(
    baselineMonthlyNet: baselineMonthlyNet,
    projectedMonthlyNet: projectedMonthlyNet,
    baselineMonthlyExpense: baselineMonthlyExpense,
    projectedMonthlyExpense: projectedMonthlyExpense,
    baselineMonthlyIncome: baselineMonthlyIncome,
    categoryImpacts: categoryImpacts,
  );
});
