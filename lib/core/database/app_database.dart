import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Table for storing encrypted transactions.
///
/// Only `id`, `date`, `lastUpdatedAt`, and `isDeleted` are stored in plaintext
/// for querying and sorting. All other transaction data is encrypted in `encryptedBlob`.
class Transactions extends Table {
  /// UUID primary key (plaintext for lookups)
  TextColumn get id => text()();

  /// Transaction date in Unix milliseconds (plaintext for sorting/filtering by date range)
  IntColumn get date => integer()();

  /// Last updated timestamp for LWW (Last-Write-Wins) sync resolution
  IntColumn get lastUpdatedAt => integer()();

  /// Soft delete flag - allows sync to propagate deletions
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// AES-GCM encrypted JSON blob containing all transaction data
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing encrypted accounts.
///
/// Only `id`, `createdAt`, `lastUpdatedAt`, and `isDeleted` are stored in plaintext
/// for querying and sorting. All other account data is encrypted in `encryptedBlob`.
class Accounts extends Table {
  /// UUID primary key (plaintext for lookups)
  TextColumn get id => text()();

  /// Account creation date in Unix milliseconds (plaintext for sorting)
  IntColumn get createdAt => integer()();

  /// Last updated timestamp for LWW (Last-Write-Wins) sync resolution
  IntColumn get lastUpdatedAt => integer()();

  /// Soft delete flag - allows sync to propagate deletions
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// AES-GCM encrypted JSON blob containing all account data
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The main application database.
///
/// Uses Drift with SQLite for local persistence. In Stage 1, the database
/// is stored unencrypted on disk, but all sensitive transaction data is
/// encrypted at the application layer before being stored.
@DriftDatabase(tables: [Transactions, Accounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Add accounts table in version 2
            await m.createTable(accounts);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cachium_db');
  }

  // CRUD operations for transactions

  /// Insert a new transaction row
  Future<void> insertTransaction({
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

  /// Update an existing transaction row
  Future<void> updateTransaction({
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
  Future<void> softDeleteTransaction(String id, int lastUpdatedAt) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  /// Get a single transaction by ID (only if not deleted)
  Future<Transaction?> getTransaction(String id) async {
    return (select(transactions)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all non-deleted transactions ordered by date descending
  Future<List<Transaction>> getAllTransactions() async {
    return (select(transactions)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Watch all non-deleted transactions (for reactive UI)
  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Check if any transactions exist (for seeding demo data)
  Future<bool> hasTransactions() async {
    final count = await (selectOnly(transactions)
          ..addColumns([transactions.id.count()]))
        .map((row) => row.read(transactions.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  // CRUD operations for accounts

  /// Insert a new account row
  Future<void> insertAccount({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(accounts).insert(
      AccountsCompanion.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
    );
  }

  /// Update an existing account row
  Future<void> updateAccount({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  /// Soft delete an account (set isDeleted = true)
  Future<void> softDeleteAccount(String id, int lastUpdatedAt) async {
    await (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  /// Get a single account by ID (only if not deleted)
  Future<Account?> getAccount(String id) async {
    return (select(accounts)
          ..where((a) => a.id.equals(id))
          ..where((a) => a.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all non-deleted accounts ordered by createdAt descending
  Future<List<Account>> getAllAccounts() async {
    return (select(accounts)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  /// Watch all non-deleted accounts (for reactive UI)
  Stream<List<Account>> watchAllAccounts() {
    return (select(accounts)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .watch();
  }

  /// Check if any accounts exist (for seeding demo data)
  Future<bool> hasAccounts() async {
    final count = await (selectOnly(accounts)
          ..addColumns([accounts.id.count()]))
        .map((row) => row.read(accounts.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }
}
