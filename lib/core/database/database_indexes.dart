import 'package:drift/drift.dart';

/// SQL index definitions for the Cachium database.
///
/// Extracted from `app_database.dart` to keep the main database class focused
/// on schema + CRUD delegation. Drift's [Migrator.customStatement] is called
/// for each index so they're created idempotently via `IF NOT EXISTS`.
///
/// Categories:
/// - Per-table `is_deleted` indexes — speed up filtered list queries
/// - Per-table `last_updated_at` indexes — used by sync/LWW resolution
/// - Composite `(is_deleted, last_updated_at)` — used by cleanup queries
/// - Miscellaneous: date, sort_order, FK indexes
const _indexStatements = <String>[
  // Transactions
  'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)',
  'CREATE INDEX IF NOT EXISTS idx_transactions_is_deleted ON transactions(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_transactions_is_deleted_date ON transactions(is_deleted, date)',

  // Accounts
  'CREATE INDEX IF NOT EXISTS idx_accounts_is_deleted ON accounts(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_accounts_sort_order ON accounts(sort_order)',

  // Categories
  'CREATE INDEX IF NOT EXISTS idx_categories_is_deleted ON categories(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON categories(sort_order)',

  // Budgets
  'CREATE INDEX IF NOT EXISTS idx_budgets_is_deleted ON budgets(is_deleted)',

  // Assets
  'CREATE INDEX IF NOT EXISTS idx_assets_is_deleted ON assets(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_asset_categories_is_deleted ON asset_categories(is_deleted)',

  // Recurring / savings / templates
  'CREATE INDEX IF NOT EXISTS idx_recurring_rules_is_deleted ON recurring_rules(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_savings_goals_is_deleted ON savings_goals(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_transaction_templates_is_deleted ON transaction_templates(is_deleted)',

  // Tags
  'CREATE INDEX IF NOT EXISTS idx_tags_is_deleted ON tags(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_tags_sort_order ON tags(sort_order)',

  // Junction / FK
  'CREATE INDEX IF NOT EXISTS idx_transaction_tags_transaction ON transaction_tags(transaction_id)',
  'CREATE INDEX IF NOT EXISTS idx_transaction_tags_tag ON transaction_tags(tag_id)',
  'CREATE INDEX IF NOT EXISTS idx_attachments_transaction ON attachments(transaction_id)',
  'CREATE INDEX IF NOT EXISTS idx_attachments_is_deleted ON attachments(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_bills_is_deleted ON bills(is_deleted)',

  // lastUpdatedAt indexes for sync/LWW resolution
  'CREATE INDEX IF NOT EXISTS idx_transactions_last_updated ON transactions(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_accounts_last_updated ON accounts(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_categories_last_updated ON categories(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_budgets_last_updated ON budgets(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_assets_last_updated ON assets(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_asset_categories_last_updated ON asset_categories(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_recurring_rules_last_updated ON recurring_rules(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_savings_goals_last_updated ON savings_goals(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_transaction_templates_last_updated ON transaction_templates(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_tags_last_updated ON tags(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_attachments_last_updated ON attachments(last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_bills_last_updated ON bills(last_updated_at)',

  // Composite indexes for cleanup queries (is_deleted + last_updated_at)
  'CREATE INDEX IF NOT EXISTS idx_transactions_deleted_updated ON transactions(is_deleted, last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_accounts_deleted_updated ON accounts(is_deleted, last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_categories_deleted_updated ON categories(is_deleted, last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_budgets_deleted_updated ON budgets(is_deleted, last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_assets_deleted_updated ON assets(is_deleted, last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_tags_deleted_updated ON tags(is_deleted, last_updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_bills_deleted_updated ON bills(is_deleted, last_updated_at)',
];

/// Creates all performance indexes on the database.
///
/// Called from [MigrationStrategy.onCreate] and `onUpgrade` in `AppDatabase`.
Future<void> createDatabaseIndexes(DatabaseConnectionUser db) async {
  for (final stmt in _indexStatements) {
    await db.customStatement(stmt);
  }
}
