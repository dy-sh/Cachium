class PeriodComparisonData {
  final PeriodMetrics periodA;
  final PeriodMetrics periodB;
  final List<CategoryComparisonItem> categoryComparison;

  const PeriodComparisonData({
    required this.periodA,
    required this.periodB,
    required this.categoryComparison,
  });

  bool get isEmpty => periodA.transactionCount == 0 && periodB.transactionCount == 0;
}

class PeriodMetrics {
  final String label;
  final double income;
  final double expense;
  final int transactionCount;

  const PeriodMetrics({
    required this.label,
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  double get net => income - expense;
}

class CategoryComparisonItem {
  final String categoryId;
  final String name;
  final double amountA;
  final double amountB;

  const CategoryComparisonItem({
    required this.categoryId,
    required this.name,
    required this.amountA,
    required this.amountB,
  });

  double get changePercent => amountA != 0 ? ((amountB - amountA) / amountA * 100) : (amountB > 0 ? 100 : 0);
}
