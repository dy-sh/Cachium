class IncomeExpenseSummary {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalIncome;
  final double totalExpense;
  final int incomeCount;
  final int expenseCount;

  const IncomeExpenseSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.totalIncome,
    required this.totalExpense,
    required this.incomeCount,
    required this.expenseCount,
  });

  double get netAmount => totalIncome - totalExpense;

  int get totalCount => incomeCount + expenseCount;

  int get dayCount {
    final diff = periodEnd.difference(periodStart).inDays;
    return diff > 0 ? diff : 1;
  }

  double get averageDailyExpense => dayCount > 0 ? totalExpense / dayCount : 0;

  double get averageDailyIncome => dayCount > 0 ? totalIncome / dayCount : 0;

  double get averageDailyNet => dayCount > 0 ? netAmount / dayCount : 0;

  double get savingsRate {
    if (totalIncome == 0) return 0;
    return ((totalIncome - totalExpense) / totalIncome * 100).clamp(-100, 100);
  }

  factory IncomeExpenseSummary.empty({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return IncomeExpenseSummary(
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalIncome: 0,
      totalExpense: 0,
      incomeCount: 0,
      expenseCount: 0,
    );
  }

  IncomeExpenseSummary copyWith({
    DateTime? periodStart,
    DateTime? periodEnd,
    double? totalIncome,
    double? totalExpense,
    int? incomeCount,
    int? expenseCount,
  }) {
    return IncomeExpenseSummary(
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      incomeCount: incomeCount ?? this.incomeCount,
      expenseCount: expenseCount ?? this.expenseCount,
    );
  }
}

class PeriodSummary {
  final DateTime periodStart;
  final DateTime periodEnd;
  final String label;
  final double income;
  final double expense;

  const PeriodSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.label,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}
