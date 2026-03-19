import 'package:drift/drift.dart';

import '../app_database.dart';

part 'account_dao.g.dart';

/// Data Access Object for account operations.
@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin {
  AccountDao(super.db);

  /// Insert a new account row
  Future<void> insert({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(accounts).insert(
      AccountsCompanion(
        id: Value(id),
        createdAt: Value(createdAt),
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  /// Insert or update an account row (upsert)
  Future<void> upsert({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) async {
    await into(accounts).insert(
      AccountsCompanion(
        id: Value(id),
        createdAt: Value(createdAt),
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
        isDeleted: Value(isDeleted),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Update an existing account row
  Future<void> updateRow({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  /// Update just the sort order for an account
  Future<void> updateSortOrder(String id, int sortOrder) async {
    await (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Soft delete an account (set isDeleted = true)
  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  /// Get a single account by ID (only if not deleted)
  Future<Account?> getById(String id) async {
    return (select(accounts)
          ..where((a) => a.id.equals(id))
          ..where((a) => a.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all non-deleted accounts ordered by sortOrder then createdAt
  Future<List<Account>> getAll() async {
    return (select(accounts)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([
            (a) => OrderingTerm.asc(a.sortOrder),
            (a) => OrderingTerm.desc(a.createdAt),
          ]))
        .get();
  }

  /// Watch all non-deleted accounts (for reactive UI)
  Stream<List<Account>> watchAll() {
    return (select(accounts)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([
            (a) => OrderingTerm.asc(a.sortOrder),
            (a) => OrderingTerm.desc(a.createdAt),
          ]))
        .watch();
  }

  /// Check if any accounts exist
  Future<bool> hasAny() async {
    final count = await (selectOnly(accounts)
          ..addColumns([accounts.id.count()]))
        .map((row) => row.read(accounts.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  /// Delete all accounts from the database
  Future<void> deleteAll() async {
    await delete(accounts).go();
  }
}
