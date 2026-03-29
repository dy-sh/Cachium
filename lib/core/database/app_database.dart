import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/account_dao.dart';
import 'daos/asset_dao.dart';
import 'daos/asset_category_dao.dart';
import 'daos/attachment_dao.dart';
import 'daos/bill_dao.dart';
import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/net_worth_snapshot_dao.dart';
import 'daos/notification_log_dao.dart';
import 'daos/recurring_rule_dao.dart';
import 'daos/savings_goal_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/transaction_tag_dao.dart';
import 'daos/transaction_template_dao.dart';

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

  /// Sort order for display ordering (plaintext for sorting)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

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

/// Table for storing encrypted asset categories.
///
/// Only `id`, `createdAt`, `lastUpdatedAt`, and `isDeleted` are stored in plaintext
/// for querying and sorting. All other data is encrypted in `encryptedBlob`.
@DataClassName('AssetCategoryRow')
class AssetCategories extends Table {
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

/// Table for storing encrypted transaction templates.
@DataClassName('TransactionTemplateRow')
class TransactionTemplates extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUpdatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing encrypted tags.
///
/// Only `id`, `sortOrder`, `lastUpdatedAt`, and `isDeleted` are stored in plaintext.
/// All other tag data is encrypted in `encryptedBlob`.
@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get lastUpdatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Junction table for transaction-tag relationships.
///
/// Plaintext — only stores opaque UUIDs.
/// Foreign keys cascade deletes so orphaned rows are impossible.
class TransactionTags extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

/// Table for storing encrypted attachment metadata.
@DataClassName('AttachmentRow')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  IntColumn get createdAt => integer()();
  IntColumn get lastUpdatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for logging sent notifications (plaintext, non-sensitive metadata).
@DataClassName('NotificationLogRow')
class NotificationLog extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get referenceId => text().nullable()();
  IntColumn get sentAt => integer()();
  IntColumn get scheduledFor => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing encrypted bills / due date reminders.
@DataClassName('BillRow')
class Bills extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUpdatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BlobColumn get encryptedBlob => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing net worth snapshots (plaintext, monthly aggregates).
@DataClassName('NetWorthSnapshotRow')
class NetWorthSnapshots extends Table {
  TextColumn get id => text()();
  IntColumn get date => integer()(); // First-of-month in Unix ms
  RealColumn get netWorth => real()();
  RealColumn get totalHoldings => real()();
  RealColumn get totalLiabilities => real()();
  TextColumn get perAccountBalancesJson => text()();
  TextColumn get mainCurrencyCode => text()();

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
  tables: [Transactions, Accounts, Categories, Budgets, Assets, AssetCategories, RecurringRules, SavingsGoals, TransactionTemplates, Tags, TransactionTags, Attachments, NotificationLog, Bills, NetWorthSnapshots, AppSettings],
  daos: [TransactionDao, AccountDao, CategoryDao, BudgetDao, AssetDao, AssetCategoryDao, RecurringRuleDao, SavingsGoalDao, TransactionTemplateDao, TagDao, TransactionTagDao, AttachmentDao, NotificationLogDao, BillDao, NetWorthSnapshotDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());


  @override
  int get schemaVersion => 29;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // App is not released — destructive migration is safe.
          // Drop all tables and recreate from scratch.
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
          }
          await m.createAll();
          await _createIndexes(m);
        },
      );

  /// Create performance indexes on commonly queried columns.
  Future<void> _createIndexes(Migrator m) async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_is_deleted ON transactions(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_is_deleted_date ON transactions(is_deleted, date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounts_is_deleted ON accounts(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounts_sort_order ON accounts(sort_order)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_is_deleted ON categories(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON categories(sort_order)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_budgets_is_deleted ON budgets(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_assets_is_deleted ON assets(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_asset_categories_is_deleted ON asset_categories(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recurring_rules_is_deleted ON recurring_rules(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_savings_goals_is_deleted ON savings_goals(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transaction_templates_is_deleted ON transaction_templates(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tags_is_deleted ON tags(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tags_sort_order ON tags(sort_order)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transaction_tags_transaction ON transaction_tags(transaction_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transaction_tags_tag ON transaction_tags(tag_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attachments_transaction ON attachments(transaction_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attachments_is_deleted ON attachments(is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bills_is_deleted ON bills(is_deleted)',
    );

    // lastUpdatedAt indexes for sync/LWW resolution
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_last_updated ON transactions(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounts_last_updated ON accounts(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_last_updated ON categories(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_budgets_last_updated ON budgets(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_assets_last_updated ON assets(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_asset_categories_last_updated ON asset_categories(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recurring_rules_last_updated ON recurring_rules(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_savings_goals_last_updated ON savings_goals(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transaction_templates_last_updated ON transaction_templates(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tags_last_updated ON tags(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attachments_last_updated ON attachments(last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bills_last_updated ON bills(last_updated_at)',
    );

    // Composite indexes for cleanup queries (is_deleted + last_updated_at)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_deleted_updated ON transactions(is_deleted, last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounts_deleted_updated ON accounts(is_deleted, last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_deleted_updated ON categories(is_deleted, last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_budgets_deleted_updated ON budgets(is_deleted, last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_assets_deleted_updated ON assets(is_deleted, last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tags_deleted_updated ON tags(is_deleted, last_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bills_deleted_updated ON bills(is_deleted, last_updated_at)',
    );
  }

  /// Remove orphaned records from join/child tables where the parent no longer exists.
  Future<int> cleanupOrphanedRecords() async {
    final tagCount = await customUpdate(
      'DELETE FROM transaction_tags WHERE transaction_id NOT IN (SELECT id FROM transactions) OR tag_id NOT IN (SELECT id FROM tags)',
      updates: {transactionTags},
      updateKind: UpdateKind.delete,
    );
    final attachmentCount = await customUpdate(
      'DELETE FROM attachments WHERE transaction_id NOT IN (SELECT id FROM transactions)',
      updates: {attachments},
      updateKind: UpdateKind.delete,
    );
    return tagCount + attachmentCount;
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'cachium_db',
      native: DriftNativeOptions(
        setup: (database) {
          // Enable WAL mode for concurrent reads/writes
          database.execute('PRAGMA journal_mode=WAL');
          // Enforce foreign key constraints at the database level
          database.execute('PRAGMA foreign_keys=ON');
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
    int sortOrder = 0,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      accountDao.insert(
        id: id,
        createdAt: createdAt,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> upsertAccount({
    required String id,
    required int createdAt,
    int sortOrder = 0,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) =>
      accountDao.upsert(
        id: id,
        createdAt: createdAt,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );

  Future<void> updateAccount({
    required String id,
    int sortOrder = 0,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      accountDao.updateRow(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> updateAccountSortOrder(String id, int sortOrder) =>
      accountDao.updateSortOrder(id, sortOrder);

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

  // CRUD operations for asset categories (delegates to AssetCategoryDao)

  Future<void> insertAssetCategory({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      assetCategoryDao.insert(
        id: id,
        createdAt: createdAt,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> upsertAssetCategory({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) =>
      assetCategoryDao.upsert(
        id: id,
        createdAt: createdAt,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );

  Future<void> updateAssetCategory({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      assetCategoryDao.updateRow(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteAssetCategory(String id, int lastUpdatedAt) =>
      assetCategoryDao.softDelete(id, lastUpdatedAt);

  Future<AssetCategoryRow?> getAssetCategory(String id) => assetCategoryDao.getById(id);

  Future<List<AssetCategoryRow>> getAllAssetCategories() => assetCategoryDao.getAll();

  Stream<List<AssetCategoryRow>> watchAllAssetCategories() => assetCategoryDao.watchAll();

  Future<bool> hasAssetCategories() => assetCategoryDao.hasAny();

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

  // CRUD operations for transaction templates (delegates to TransactionTemplateDao)

  Future<void> insertTransactionTemplate({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      transactionTemplateDao.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> updateTransactionTemplate({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      transactionTemplateDao.updateRow(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteTransactionTemplate(String id, int lastUpdatedAt) =>
      transactionTemplateDao.softDelete(id, lastUpdatedAt);

  Future<List<TransactionTemplateRow>> getAllTransactionTemplates() =>
      transactionTemplateDao.getAll();

  Stream<List<TransactionTemplateRow>> watchAllTransactionTemplates() =>
      transactionTemplateDao.watchAll();

  Future<void> deleteAllTransactionTemplates() => transactionTemplateDao.deleteAll();

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

  // CRUD operations for tags (delegates to TagDao)

  Future<void> insertTag({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      tagDao.insert(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> upsertTag({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) =>
      tagDao.upsert(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );

  Future<void> updateTag({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      tagDao.updateRow(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteTag(String id, int lastUpdatedAt) =>
      tagDao.softDelete(id, lastUpdatedAt);

  Future<TagRow?> getTag(String id) => tagDao.getById(id);

  Future<List<TagRow>> getAllTags() => tagDao.getAll();

  Stream<List<TagRow>> watchAllTags() => tagDao.watchAll();

  Future<bool> hasTags() => tagDao.hasAny();

  Future<void> deleteAllTags() => tagDao.deleteAll();

  // TransactionTag operations (delegates to TransactionTagDao)

  Future<void> addTransactionTag({
    required String transactionId,
    required String tagId,
  }) =>
      transactionTagDao.addTag(transactionId: transactionId, tagId: tagId);

  Future<void> removeTransactionTag({
    required String transactionId,
    required String tagId,
  }) =>
      transactionTagDao.removeTag(transactionId: transactionId, tagId: tagId);

  Future<List<String>> getTagIdsForTransaction(String transactionId) =>
      transactionTagDao.getTagIdsForTransaction(transactionId);

  Future<List<String>> getTransactionIdsForTag(String tagId) =>
      transactionTagDao.getTransactionIdsForTag(tagId);

  Future<void> setTagsForTransaction(String transactionId, List<String> tagIds) =>
      transactionTagDao.setTagsForTransaction(transactionId, tagIds);

  Future<void> removeAllTagsForTag(String tagId) =>
      transactionTagDao.removeAllForTag(tagId);

  Future<void> deleteAllTransactionTags() => transactionTagDao.deleteAll();

  // CRUD operations for attachments (delegates to AttachmentDao)

  Future<void> insertAttachment({
    required String id,
    required String transactionId,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      attachmentDao.insert(
        id: id,
        transactionId: transactionId,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> updateAttachment({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      attachmentDao.updateRow(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteAttachment(String id, int lastUpdatedAt) =>
      attachmentDao.softDelete(id, lastUpdatedAt);

  Future<AttachmentRow?> getAttachment(String id) => attachmentDao.getById(id);

  Future<List<AttachmentRow>> getAttachmentsByTransactionId(String transactionId) =>
      attachmentDao.getByTransactionId(transactionId);

  Stream<List<AttachmentRow>> watchAttachmentsByTransactionId(String transactionId) =>
      attachmentDao.watchByTransactionId(transactionId);

  Future<List<AttachmentRow>> getAllAttachments() => attachmentDao.getAll();

  Future<void> deleteAllAttachments() => attachmentDao.deleteAll();

  // CRUD operations for bills (delegates to BillDao)

  Future<void> insertBill({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      billDao.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> upsertBill({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) =>
      billDao.upsert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );

  Future<void> updateBill({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) =>
      billDao.updateRow(
        id: id,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      );

  Future<void> softDeleteBill(String id, int lastUpdatedAt) =>
      billDao.softDelete(id, lastUpdatedAt);

  Future<List<BillRow>> getAllBills() => billDao.getAll();

  Stream<List<BillRow>> watchAllBills() => billDao.watchAll();

  Future<void> deleteAllBills() => billDao.deleteAll();

  // Net Worth Snapshot operations (delegates to NetWorthSnapshotDao)
  // Direct access via netWorthSnapshotDao for repository use

  Future<void> deleteAllNetWorthSnapshots() => netWorthSnapshotDao.deleteAll();

  // NotificationLog operations (delegates to NotificationLogDao)

  Future<void> insertNotificationLog({
    required String id,
    required String type,
    String? referenceId,
    required int sentAt,
    int? scheduledFor,
  }) =>
      notificationLogDao.insert(
        id: id,
        type: type,
        referenceId: referenceId,
        sentAt: sentAt,
        scheduledFor: scheduledFor,
      );

  Future<List<NotificationLogRow>> getAllNotificationLogs() =>
      notificationLogDao.getAll();

  Future<bool> wasNotificationSentRecently({
    required String type,
    required String referenceId,
    required Duration within,
  }) =>
      notificationLogDao.wasSentRecently(
        type: type,
        referenceId: referenceId,
        within: within,
      );

  Future<void> deleteAllNotificationLogs() => notificationLogDao.deleteAll();

  Future<void> cleanupOldNotificationLogs(Duration olderThan) =>
      notificationLogDao.cleanupOlderThan(olderThan);

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

  Future<void> deleteAllAssetCategories() => assetCategoryDao.deleteAll();

  Future<void> deleteAllSettings() => settingsDao.deleteAll();

  /// Permanently deletes soft-deleted records older than the given threshold.
  Future<void> cleanupDeletedRecords({
    Duration olderThan = const Duration(days: 30),
  }) async {
    final cutoff = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
    await transaction(() async {
      await customStatement(
        'DELETE FROM transactions WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM accounts WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM categories WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM budgets WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM assets WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM recurring_rules WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM savings_goals WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM transaction_templates WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM tags WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM attachments WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
      await customStatement(
        'DELETE FROM bills WHERE is_deleted = 1 AND last_updated_at < ?',
        [cutoff],
      );
    });
  }

  Future<void> deleteAllData({bool includeSettings = false}) async {
    await transaction(() async {
      await deleteAllTransactions();
      await deleteAllAccounts();
      await deleteAllCategories();
      await deleteAllBudgets();
      await deleteAllAssets();
      await deleteAllAssetCategories();
      await deleteAllRecurringRules();
      await deleteAllSavingsGoals();
      await deleteAllTransactionTemplates();
      await deleteAllTags();
      await deleteAllTransactionTags();
      await deleteAllAttachments();
      await deleteAllBills();
      await deleteAllNetWorthSnapshots();
      if (includeSettings) {
        await deleteAllSettings();
      }
    });
  }
}
