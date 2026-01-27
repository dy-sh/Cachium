class SpendingTrend {
  final String categoryId;
  final String categoryName;
  final double currentAmount;
  final double previousAmount;
  final double changePercent;
  final bool isIncrease;

  const SpendingTrend({
    required this.categoryId,
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.changePercent,
    required this.isIncrease,
  });
}

class OverallTrend {
  final double currentIncome;
  final double previousIncome;
  final double currentExpense;
  final double previousExpense;
  final double incomeChangePercent;
  final double expenseChangePercent;
  final List<SpendingTrend> topCategoryChanges;

  const OverallTrend({
    required this.currentIncome,
    required this.previousIncome,
    required this.currentExpense,
    required this.previousExpense,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.topCategoryChanges,
  });

  bool get hasData => currentIncome > 0 || currentExpense > 0 || previousIncome > 0 || previousExpense > 0;
}
