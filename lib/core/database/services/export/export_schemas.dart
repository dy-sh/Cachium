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

const _plaintextTableSchemas = <String>[
  '''
    CREATE TABLE transactions (
      id TEXT PRIMARY KEY,
      date INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      amount REAL NOT NULL,
      category_id TEXT NOT NULL,
      account_id TEXT NOT NULL,
      type TEXT NOT NULL,
      note TEXT,
      currency TEXT NOT NULL DEFAULT 'USD',
      conversion_rate REAL NOT NULL DEFAULT 1.0,
      main_currency_code TEXT NOT NULL DEFAULT 'USD',
      main_currency_amount REAL,
      destination_account_id TEXT,
      destination_amount REAL,
      merchant TEXT,
      asset_id TEXT,
      is_acquisition_cost INTEGER NOT NULL DEFAULT 0,
      date_millis INTEGER NOT NULL,
      created_at_millis INTEGER NOT NULL
    )
  ''',
  '''
    CREATE TABLE accounts (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      balance REAL NOT NULL,
      initial_balance REAL NOT NULL DEFAULT 0,
      currency_code TEXT NOT NULL DEFAULT 'USD',
      custom_color_value INTEGER,
      custom_icon_code_point INTEGER,
      custom_icon_font_family TEXT,
      custom_icon_font_package TEXT,
      created_at_millis INTEGER NOT NULL
    )
  ''',
  '''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      sort_order INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      icon_code_point INTEGER NOT NULL,
      icon_font_family TEXT NOT NULL,
      icon_font_package TEXT,
      color_index INTEGER NOT NULL,
      type TEXT NOT NULL,
      is_custom INTEGER NOT NULL DEFAULT 0,
      parent_id TEXT,
      show_assets INTEGER NOT NULL DEFAULT 0
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
      category_id TEXT NOT NULL,
      amount REAL NOT NULL,
      year INTEGER NOT NULL,
      month INTEGER NOT NULL,
      created_at_millis INTEGER NOT NULL
    )
  ''',
  '''
    CREATE TABLE assets (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      icon_code_point INTEGER NOT NULL,
      icon_font_family TEXT,
      icon_font_package TEXT,
      color_index INTEGER NOT NULL,
      status TEXT NOT NULL,
      note TEXT,
      purchase_price REAL,
      purchase_currency_code TEXT,
      asset_category_id TEXT,
      purchase_date_millis INTEGER,
      created_at_millis INTEGER NOT NULL
    )
  ''',
  '''
    CREATE TABLE asset_categories (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      icon_code_point INTEGER NOT NULL,
      icon_font_family TEXT,
      icon_font_package TEXT,
      color_index INTEGER NOT NULL,
      created_at_millis INTEGER NOT NULL
    )
  ''',
  '''
    CREATE TABLE recurring_rules (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category_id TEXT NOT NULL,
      account_id TEXT NOT NULL,
      destination_account_id TEXT,
      merchant TEXT,
      note TEXT,
      currency_code TEXT NOT NULL DEFAULT 'USD',
      destination_amount REAL,
      frequency TEXT NOT NULL,
      start_date_millis INTEGER NOT NULL,
      end_date_millis INTEGER,
      last_generated_date_millis INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at_millis INTEGER NOT NULL
    )
  ''',
  '''
    CREATE TABLE savings_goals (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL NOT NULL DEFAULT 0,
      color_index INTEGER NOT NULL,
      icon_code_point INTEGER NOT NULL,
      icon_font_family TEXT,
      icon_font_package TEXT,
      linked_account_id TEXT,
      target_date_millis INTEGER,
      note TEXT,
      created_at_millis INTEGER NOT NULL
    )
  ''',
  '''
    CREATE TABLE transaction_templates (
      id TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      last_updated_at INTEGER NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      amount REAL,
      type TEXT NOT NULL,
      category_id TEXT,
      account_id TEXT,
      destination_account_id TEXT,
      asset_id TEXT,
      merchant TEXT,
      note TEXT,
      created_at_millis INTEGER NOT NULL
    )
  ''',
];

/// Create the encrypted-blob export schema (mirrors production tables).
void createEncryptedExportSchema(sql.Database db) {
  for (final stmt in _encryptedTableSchemas) {
    db.execute(stmt);
  }
}

/// Create the expanded plaintext export schema (all fields inline).
void createPlaintextExportSchema(sql.Database db) {
  for (final stmt in _plaintextTableSchemas) {
    db.execute(stmt);
  }
}
