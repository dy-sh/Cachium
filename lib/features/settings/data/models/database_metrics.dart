/// Statistics about the database contents.
class DatabaseMetrics {
  final int transactionCount;
  final int categoryCount;
  final int accountCount;
  final DateTime? oldestRecord;
  final DateTime? newestRecord;

  const DatabaseMetrics({
    required this.transactionCount,
    required this.categoryCount,
    required this.accountCount,
    this.oldestRecord,
    this.newestRecord,
  });

  int get totalRecords => transactionCount + categoryCount + accountCount;

  bool get isEmpty => totalRecords == 0;
}
