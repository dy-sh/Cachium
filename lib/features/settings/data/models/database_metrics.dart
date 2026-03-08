/// Statistics about the database contents.
class DatabaseMetrics {
  final int transactionCount;
  final int categoryCount;
  final int accountCount;
  final int budgetCount;
  final int assetCount;
  final int recurringRuleCount;
  final int savingsGoalCount;
  final int templateCount;
  final DateTime? oldestRecord;
  final DateTime? newestRecord;

  const DatabaseMetrics({
    required this.transactionCount,
    required this.categoryCount,
    required this.accountCount,
    this.budgetCount = 0,
    this.assetCount = 0,
    this.recurringRuleCount = 0,
    this.savingsGoalCount = 0,
    this.templateCount = 0,
    this.oldestRecord,
    this.newestRecord,
  });

  int get totalRecords => transactionCount + categoryCount + accountCount + budgetCount + assetCount + recurringRuleCount + savingsGoalCount + templateCount;

  bool get isEmpty => totalRecords == 0;
}
