import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/waterfall_entry.dart';
import 'category_breakdown_provider.dart';
import 'income_expense_summary_provider.dart';

final waterfallProvider = Provider<List<WaterfallEntry>>((ref) {
  final summary = ref.watch(incomeExpenseSummaryProvider);
  final breakdowns = ref.watch(categoryBreakdownProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);

  if (summary.totalIncome == 0 && summary.totalExpense == 0) return [];

  final entries = <WaterfallEntry>[];
  double runningTotal = 0;

  // Income entry
  if (summary.totalIncome > 0) {
    runningTotal += summary.totalIncome;
    entries.add(WaterfallEntry(
      label: 'Income',
      amount: summary.totalIncome,
      runningTotal: runningTotal,
      type: WaterfallEntryType.income,
      color: AppColors.getTransactionColor('income', colorIntensity),
    ));
  }

  // Top expense categories (max 5)
  final topExpenses = breakdowns.take(5).toList();
  for (final b in topExpenses) {
    runningTotal -= b.amount;
    entries.add(WaterfallEntry(
      label: b.name,
      amount: -b.amount,
      runningTotal: runningTotal,
      type: WaterfallEntryType.expense,
      color: AppColors.getTransactionColor('expense', colorIntensity),
      categoryId: b.categoryId,
    ));
  }

  // Remaining expenses (if any)
  final topTotal = topExpenses.fold(0.0, (s, b) => s + b.amount);
  final remaining = summary.totalExpense - topTotal;
  if (remaining > 0) {
    runningTotal -= remaining;
    entries.add(WaterfallEntry(
      label: 'Other',
      amount: -remaining,
      runningTotal: runningTotal,
      type: WaterfallEntryType.expense,
      color: AppColors.getTransactionColor('expense', colorIntensity),
    ));
  }

  // Net total
  entries.add(WaterfallEntry(
    label: 'Net',
    amount: summary.netAmount,
    runningTotal: runningTotal,
    type: WaterfallEntryType.netTotal,
    color: ref.watch(accentColorProvider),
  ));

  return entries;
});
