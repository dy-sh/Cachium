enum YoYGrouping { monthly, quarterly }

class YoYPeriodData {
  final int periodIndex; // 1-12 for monthly, 1-4 for quarterly
  final String label;
  final double income;
  final double expense;

  const YoYPeriodData({
    required this.periodIndex,
    required this.label,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

class YearOverYearSummary {
  final int year;
  final List<YoYPeriodData> periods;

  const YearOverYearSummary({
    required this.year,
    required this.periods,
  });

  double get totalIncome => periods.fold(0, (s, p) => s + p.income);
  double get totalExpense => periods.fold(0, (s, p) => s + p.expense);
  double get totalNet => totalIncome - totalExpense;
}
