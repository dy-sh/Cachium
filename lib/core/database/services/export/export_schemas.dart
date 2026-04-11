import 'package:sqlite3/sqlite3.dart' as sql;

/// SQL schema DDL for exported SQLite databases.
///
/// Extracted from `database_export_service.dart`. Two shapes exist:
/// - **Encrypted**: mirror of the production schema (`encrypted_blob` plus
///   plaintext metadata only). Used when the user enables encryption at
///   export time so the output file is useless without the encryption key.
/// - **Plaintext**: expands every field for human/third-party inspection.
///
/// Both variants produce a database with the same table *names* so import
/// code can sniff the shape via `PRAGMA table_info(...)`.

const _encryptedTableSchemas = <String>[
  '''
    CREATE TABLE transactions (
      id TEXT PRIMARY KEY,
      date INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
  '''
    CREATE TABLE accounts (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
  '''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      sort_order INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
  '''
    CREATE TABLE app_settings (
      id TEXT PRIMARY KEY,
      last_updated_at INTEGER NOT NULL,
      json_data TEXT NOT NULL
    )
  ''',
  '''
    CREATE TABLE budgets (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
  '''
    CREATE TABLE assets (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
  '''
    CREATE TABLE asset_categories (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
  '''
    CREATE TABLE recurring_rules (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
  '''
    CREATE TABLE savings_goals (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
  '''
    CREATE TABLE transaction_templates (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      encrypted_blob BLOB NOT NULL
    )
  ''',
];

/// Create the encrypted-blob export schema (mirrors production tables).
void createEncryptedExportSchema(sql.Database db) {
  for (final stmt in _encryptedTableSchemas) {
    db.execute(stmt);
  }
}
