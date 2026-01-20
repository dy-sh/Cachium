import '../../../features/settings/data/models/database_metrics.dart';
import '../app_database.dart';
import 'package:drift/drift.dart';

/// Service for querying database statistics.
class DatabaseMetricsService {
  final AppDatabase database;

  DatabaseMetricsService({required this.database});

  /// Get counts and timestamps for all data in the database.
  Future<DatabaseMetrics> getMetrics() async {
    final transactionCount = await _getTransactionCount();
    final categoryCount = await _getCategoryCount();
    final accountCount = await _getAccountCount();
    final oldestRecord = await _getOldestRecordDate();
    final newestRecord = await _getNewestRecordDate();

    return DatabaseMetrics(
      transactionCount: transactionCount,
      categoryCount: categoryCount,
      accountCount: accountCount,
      oldestRecord: oldestRecord,
      newestRecord: newestRecord,
    );
  }

  Future<int> _getTransactionCount() async {
    final query = database.selectOnly(database.transactions)
      ..addColumns([database.transactions.id.count()])
      ..where(database.transactions.isDeleted.equals(false));

    final result = await query.getSingle();
    return result.read(database.transactions.id.count()) ?? 0;
  }

  Future<int> _getCategoryCount() async {
    final query = database.selectOnly(database.categories)
      ..addColumns([database.categories.id.count()])
      ..where(database.categories.isDeleted.equals(false));

    final result = await query.getSingle();
    return result.read(database.categories.id.count()) ?? 0;
  }

  Future<int> _getAccountCount() async {
    final query = database.selectOnly(database.accounts)
      ..addColumns([database.accounts.id.count()])
      ..where(database.accounts.isDeleted.equals(false));

    final result = await query.getSingle();
    return result.read(database.accounts.id.count()) ?? 0;
  }

  Future<DateTime?> _getOldestRecordDate() async {
    // Get the minimum date from transactions
    final transactionQuery = database.selectOnly(database.transactions)
      ..addColumns([database.transactions.date.min()])
      ..where(database.transactions.isDeleted.equals(false));

    // Get the minimum createdAt from accounts
    final accountQuery = database.selectOnly(database.accounts)
      ..addColumns([database.accounts.createdAt.min()])
      ..where(database.accounts.isDeleted.equals(false));

    final transactionResult = await transactionQuery.getSingle();
    final accountResult = await accountQuery.getSingle();

    final transactionDate = transactionResult.read(database.transactions.date.min());
    final accountDate = accountResult.read(database.accounts.createdAt.min());

    DateTime? oldest;

    if (transactionDate != null) {
      oldest = DateTime.fromMillisecondsSinceEpoch(transactionDate);
    }

    if (accountDate != null) {
      final accountDateTime = DateTime.fromMillisecondsSinceEpoch(accountDate);
      if (oldest == null || accountDateTime.isBefore(oldest)) {
        oldest = accountDateTime;
      }
    }

    return oldest;
  }

  Future<DateTime?> _getNewestRecordDate() async {
    // Get the maximum lastUpdatedAt from transactions
    final transactionQuery = database.selectOnly(database.transactions)
      ..addColumns([database.transactions.lastUpdatedAt.max()])
      ..where(database.transactions.isDeleted.equals(false));

    // Get the maximum lastUpdatedAt from accounts
    final accountQuery = database.selectOnly(database.accounts)
      ..addColumns([database.accounts.lastUpdatedAt.max()])
      ..where(database.accounts.isDeleted.equals(false));

    // Get the maximum lastUpdatedAt from categories
    final categoryQuery = database.selectOnly(database.categories)
      ..addColumns([database.categories.lastUpdatedAt.max()])
      ..where(database.categories.isDeleted.equals(false));

    final transactionResult = await transactionQuery.getSingle();
    final accountResult = await accountQuery.getSingle();
    final categoryResult = await categoryQuery.getSingle();

    final transactionDate = transactionResult.read(database.transactions.lastUpdatedAt.max());
    final accountDate = accountResult.read(database.accounts.lastUpdatedAt.max());
    final categoryDate = categoryResult.read(database.categories.lastUpdatedAt.max());

    DateTime? newest;

    if (transactionDate != null) {
      newest = DateTime.fromMillisecondsSinceEpoch(transactionDate);
    }

    if (accountDate != null) {
      final accountDateTime = DateTime.fromMillisecondsSinceEpoch(accountDate);
      if (newest == null || accountDateTime.isAfter(newest)) {
        newest = accountDateTime;
      }
    }

    if (categoryDate != null) {
      final categoryDateTime = DateTime.fromMillisecondsSinceEpoch(categoryDate);
      if (newest == null || categoryDateTime.isAfter(newest)) {
        newest = categoryDateTime;
      }
    }

    return newest;
  }
}
