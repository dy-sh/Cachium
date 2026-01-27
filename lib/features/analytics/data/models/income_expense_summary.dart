class IncomeExpenseSummary {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalIncome;
  final double totalExpense;
  final int incomeCount;
  final int expenseCount;
  final double previousTotalIncome;
  final double previousTotalExpense;

  const IncomeExpenseSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.totalIncome,
    required this.totalExpense,
    required this.incomeCount,
    required this.expenseCount,
    this.previousTotalIncome = 0,
    this.previousTotalExpense = 0,
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

  double get previousNetAmount => previousTotalIncome - previousTotalExpense;

  double get incomeChangePercent {
    if (previousTotalIncome == 0) return totalIncome > 0 ? 100 : 0;
    return (totalIncome - previousTotalIncome) / previousTotalIncome * 100;
  }

  double get expenseChangePercent {
    if (previousTotalExpense == 0) return totalExpense > 0 ? 100 : 0;
    return (totalExpense - previousTotalExpense) / previousTotalExpense * 100;
  }

  double get netChangePercent {
    if (previousNetAmount == 0) return netAmount > 0 ? 100 : (netAmount < 0 ? -100 : 0);
    return (netAmount - previousNetAmount) / previousNetAmount.abs() * 100;
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
    double? previousTotalIncome,
    double? previousTotalExpense,
  }) {
    return IncomeExpenseSummary(
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      incomeCount: incomeCount ?? this.incomeCount,
      expenseCount: expenseCount ?? this.expenseCount,
      previousTotalIncome: previousTotalIncome ?? this.previousTotalIncome,
      previousTotalExpense: previousTotalExpense ?? this.previousTotalExpense,
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

  PeriodSummary copyWith({
    DateTime? periodStart,
    DateTime? periodEnd,
    String? label,
    double? income,
    double? expense,
  }) {
    return PeriodSummary(
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      label: label ?? this.label,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}
