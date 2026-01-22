import 'package:drift/drift.dart';

import '../app_database.dart';

part 'transaction_dao.g.dart';

/// Data Access Object for transaction operations.
@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// Insert a new transaction row
  Future<void> insert({
    required String id,
    required int date,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(transactions).insert(
      TransactionsCompanion.insert(
        id: id,
        date: date,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
    );
  }

  /// Insert or update a transaction row (upsert)
  Future<void> upsert({
    required String id,
    required int date,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(transactions).insert(
      TransactionsCompanion.insert(
        id: id,
        date: date,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Update an existing transaction row
  Future<void> updateRow({
    required String id,
    required int date,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        date: Value(date),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  /// Soft delete a transaction (set isDeleted = true)
  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  /// Get a single transaction by ID (only if not deleted)
  Future<Transaction?> getById(String id) async {
    return (select(transactions)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all non-deleted transactions ordered by date descending
  Future<List<Transaction>> getAll() async {
    return (select(transactions)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Watch all non-deleted transactions (for reactive UI)
  Stream<List<Transaction>> watchAll() {
    return (select(transactions)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Check if any transactions exist
  Future<bool> hasAny() async {
    final count = await (selectOnly(transactions)
          ..addColumns([transactions.id.count()]))
        .map((row) => row.read(transactions.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  /// Delete all transactions from the database
  Future<void> deleteAll() async {
    await delete(transactions).go();
  }
}
