import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/account_dao.dart';
import 'daos/asset_dao.dart';
import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/recurring_rule_dao.dart';
import 'daos/savings_goal_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/transaction_dao.dart';

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

/// Table for storing encrypted categories.
///
/// Only `id`, `sortOrder`, `lastUpdatedAt`, and `isDeleted` are stored in plaintext
/// for querying and sorting. All other category data is encrypted in `encryptedBlob`.
@DataClassName('CategoryRow')
class Categories extends Table {
  /// UUID primary key (plaintext for lookups)
  TextColumn get id => text()();

  /// Sort order for display ordering (plaintext for sorting)
  IntColumn get sortOrder => integer()();

  /// Last updated timestamp for LWW (Last-Write-Wins) sync resolution
  IntColumn get lastUpdatedAt => integer()();

  /// Soft delete flag - allows sync to propagate deletions
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// AES-GCM encrypted JSON blob containing all category data
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing encrypted budgets.
///
/// Only `id`, `createdAt`, `lastUpdatedAt`, and `isDeleted` are stored in plaintext
/// for querying and sorting. All other budget data is encrypted in `encryptedBlob`.
@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUpdatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing encrypted assets.
///
/// Only `id`, `createdAt`, `lastUpdatedAt`, and `isDeleted` are stored in plaintext
/// for querying and sorting. All other asset data is encrypted in `encryptedBlob`.
@DataClassName('Asset')
class Assets extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get lastUpdatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing encrypted recurring transaction rules.
@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUpdatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing encrypted savings goals.
@DataClassName('SavingsGoalRow')
class SavingsGoals extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUpdatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing app settings.
///
/// Settings are stored as unencrypted JSON since they don't contain sensitive data.
/// Uses a single-row pattern with a fixed ID ('app_settings').
class AppSettings extends Table {
  /// Fixed ID - always 'app_settings' (single-row pattern)
  TextColumn get id => text()();

  /// Last updated timestamp for sync resolution
  IntColumn get lastUpdatedAt => integer()();

  /// JSON-encoded settings data
  TextColumn get jsonData => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The main application database.
///
/// Uses Drift with SQLite for local persistence. In Stage 1, the database
/// is stored unencrypted on disk, but all sensitive transaction data is
/// encrypted at the application layer before being stored.
@DriftDatabase(
  tables: [Transactions, Accounts, Categories, Budgets, Assets, RecurringRules, SavingsGoals, AppSettings],
  daos: [TransactionDao, AccountDao, CategoryDao, BudgetDao, AssetDao, RecurringRuleDao, SavingsGoalDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());


  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Recreate database on upgrade - no migration needed
          // Delete and recreate all tables
          await m.deleteTable('transactions');
          await m.deleteTable('accounts');
          await m.deleteTable('categories');
          await m.deleteTable('budgets');
          await m.deleteTable('assets');
          await m.deleteTable('recurring_rules');
          await m.deleteTable('savings_goals');
          await m.deleteTable('app_settings');
          await m.createAll();
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'cachium_db',
      native: DriftNativeOptions(
        setup: (database) {
          // Enable WAL mode for concurrent reads/writes
          database.execute('PRAGMA journal_mode=WAL');
          // Set busy timeout to 5 seconds to wait for locks instead of failing immediately
          database.execute('PRAGMA busy_timeout=5000');
        },
      ),
    );
  }

  // CRUD operations for transactions (delegates to TransactionDao)

  Future<void> insertTransaction({
    required String id,
    required int date,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      transactionDao.insert(
        id: id,
        date: date,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> upsertTransaction({
    required String id,
    required int date,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) =>
      transactionDao.upsert(
        id: id,
        date: date,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );

  Future<void> updateTransaction({
    required String id,
    required int date,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      transactionDao.updateRow(
        id: id,
        date: date,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteTransaction(String id, int lastUpdatedAt) =>
      transactionDao.softDelete(id, lastUpdatedAt);

  Future<void> restoreTransaction(String id, int lastUpdatedAt) =>
      transactionDao.restore(id, lastUpdatedAt);

  Future<Transaction?> getTransaction(String id) => transactionDao.getById(id);

  Future<List<Transaction>> getAllTransactions() => transactionDao.getAll();

  Future<List<Transaction>> getAllDeletedTransactions() => transactionDao.getAllDeleted();

  Stream<List<Transaction>> watchAllTransactions() => transactionDao.watchAll();

  Future<bool> hasTransactions() => transactionDao.hasAny();

  // CRUD operations for accounts (delegates to AccountDao)

  Future<void> insertAccount({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      accountDao.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> upsertAccount({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) =>
      accountDao.upsert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );

  Future<void> updateAccount({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      accountDao.updateRow(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteAccount(String id, int lastUpdatedAt) =>
      accountDao.softDelete(id, lastUpdatedAt);

  Future<Account?> getAccount(String id) => accountDao.getById(id);

  Future<List<Account>> getAllAccounts() => accountDao.getAll();

  Stream<List<Account>> watchAllAccounts() => accountDao.watchAll();

  Future<bool> hasAccounts() => accountDao.hasAny();

  // CRUD operations for categories (delegates to CategoryDao)

  Future<void> insertCategory({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      categoryDao.insert(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> upsertCategory({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) =>
      categoryDao.upsert(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );

  Future<void> updateCategory({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      categoryDao.updateRow(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteCategory(String id, int lastUpdatedAt) =>
      categoryDao.softDelete(id, lastUpdatedAt);

  Future<CategoryRow?> getCategory(String id) => categoryDao.getById(id);

  Future<List<CategoryRow>> getAllCategories() => categoryDao.getAll();

  Stream<List<CategoryRow>> watchAllCategories() => categoryDao.watchAll();

  Future<bool> hasCategories() => categoryDao.hasAny();

  // CRUD operations for budgets (delegates to BudgetDao)

  Future<void> insertBudget({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      budgetDao.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> updateBudget({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      budgetDao.updateRow(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteBudget(String id, int lastUpdatedAt) =>
      budgetDao.softDelete(id, lastUpdatedAt);

  Future<List<BudgetRow>> getAllBudgets() => budgetDao.getAll();

  // CRUD operations for assets (delegates to AssetDao)

  Future<void> insertAsset({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      assetDao.insert(
        id: id,
        createdAt: createdAt,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> upsertAsset({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) =>
      assetDao.upsert(
        id: id,
        createdAt: createdAt,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );

  Future<void> updateAsset({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      assetDao.updateRow(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteAsset(String id, int lastUpdatedAt) =>
      assetDao.softDelete(id, lastUpdatedAt);

  Future<Asset?> getAsset(String id) => assetDao.getById(id);

  Future<List<Asset>> getAllAssets() => assetDao.getAll();

  Stream<List<Asset>> watchAllAssets() => assetDao.watchAll();

  Future<bool> hasAssets() => assetDao.hasAny();

  // CRUD operations for recurring rules (delegates to RecurringRuleDao)

  Future<void> insertRecurringRule({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      recurringRuleDao.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> updateRecurringRule({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      recurringRuleDao.updateRow(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteRecurringRule(String id, int lastUpdatedAt) =>
      recurringRuleDao.softDelete(id, lastUpdatedAt);

  Future<List<RecurringRuleRow>> getAllRecurringRules() =>
      recurringRuleDao.getAll();

  Stream<List<RecurringRuleRow>> watchAllRecurringRules() =>
      recurringRuleDao.watchAll();

  Future<void> deleteAllRecurringRules() => recurringRuleDao.deleteAll();

  // CRUD operations for savings goals (delegates to SavingsGoalDao)

  Future<void> insertSavingsGoal({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      savingsGoalDao.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> updateSavingsGoal({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      savingsGoalDao.updateRow(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteSavingsGoal(String id, int lastUpdatedAt) =>
      savingsGoalDao.softDelete(id, lastUpdatedAt);

  Future<List<SavingsGoalRow>> getAllSavingsGoals() =>
      savingsGoalDao.getAll();

  Stream<List<SavingsGoalRow>> watchAllSavingsGoals() =>
      savingsGoalDao.watchAll();

  Future<void> deleteAllSavingsGoals() => savingsGoalDao.deleteAll();

  // CRUD operations for app settings (delegates to SettingsDao)

  Future<void> upsertSettings({
    required String id,
    required int lastUpdatedAt,
    required String jsonData,
  }) =>
      settingsDao.upsert(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        jsonData: jsonData,
      );

  Future<AppSetting?> getSettings(String id) => settingsDao.getById(id);

  Future<bool> hasSettings(String id) => settingsDao.exists(id);

  // Database management operations (delegates to DAOs)

  Future<void> deleteAllTransactions() => transactionDao.deleteAll();

  Future<void> deleteAllAccounts() => accountDao.deleteAll();

  Future<void> deleteAllCategories() => categoryDao.deleteAll();

  Future<void> deleteAllBudgets() => budgetDao.deleteAll();

  Future<void> deleteAllAssets() => assetDao.deleteAll();

  Future<void> deleteAllSettings() => settingsDao.deleteAll();

  Future<void> deleteAllData({bool includeSettings = false}) async {
    await transaction(() async {
      await deleteAllTransactions();
      await deleteAllAccounts();
      await deleteAllCategories();
      await deleteAllBudgets();
      await deleteAllAssets();
      await deleteAllRecurringRules();
      await deleteAllSavingsGoals();
      if (includeSettings) {
        await deleteAllSettings();
      }
    });
  }
}
