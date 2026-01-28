class SavingsGoal {
  final double targetAmount;
  final double currentSaved;
  final double projectedMonthlySavings;
  final DateTime? estimatedCompletionDate;
  final List<SavingsGoalPoint> projectedPath;

  const SavingsGoal({
    required this.targetAmount,
    required this.currentSaved,
    required this.projectedMonthlySavings,
    this.estimatedCompletionDate,
    required this.projectedPath,
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentSaved / targetAmount * 100).clamp(0, 100) : 0;

  double get remainingAmount => (targetAmount - currentSaved).clamp(0, double.infinity);

  int? get monthsToGoal {
    if (projectedMonthlySavings <= 0 || remainingAmount <= 0) return null;
    return (remainingAmount / projectedMonthlySavings).ceil();
  }
}

class SavingsGoalPoint {
  final DateTime date;
  final double amount;

  const SavingsGoalPoint({
    required this.date,
    required this.amount,
  });
}
