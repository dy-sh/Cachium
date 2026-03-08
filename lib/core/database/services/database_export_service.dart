import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../../data/encryption/account_data.dart';
import '../../../data/encryption/asset_data.dart';
import '../../../data/encryption/budget_data.dart';
import '../../../data/encryption/category_data.dart';
import '../../../data/encryption/recurring_rule_data.dart';
import '../../../data/encryption/savings_goal_data.dart';
import '../../../data/encryption/transaction_data.dart';
import '../../../data/encryption/transaction_template_data.dart';
import '../../../features/settings/data/models/export_options.dart';
import '../app_database.dart';
import 'encryption_service.dart';

/// Service for exporting database data to SQLite or CSV formats.
class DatabaseExportService {
  final AppDatabase database;
  final EncryptionService encryptionService;

  DatabaseExportService({
    required this.database,
    required this.encryptionService,
  });

  /// Export database to SQLite format.
  /// Returns the path to the exported file.
  Future<String> exportToSqlite(ExportOptions options) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dbPath = '${tempDir.path}/cachium_export_$timestamp.db';

    final exportDb = sql.sqlite3.open(dbPath);

    try {
      if (options.encryptionEnabled) {
        await _createEncryptedSchema(exportDb);
        await _exportTransactionsEncrypted(exportDb);
        await _exportAccountsEncrypted(exportDb);
        await _exportCategoriesEncrypted(exportDb);
        await _exportSettingsEncrypted(exportDb);
        await _exportBudgetsEncrypted(exportDb);
        await _exportAssetsEncrypted(exportDb);
        await _exportRecurringRulesEncrypted(exportDb);
        await _exportSavingsGoalsEncrypted(exportDb);
        await _exportTransactionTemplatesEncrypted(exportDb);
      } else {
        await _createPlaintextSchema(exportDb);
        await _exportTransactionsPlaintext(exportDb);
        await _exportAccountsPlaintext(exportDb);
        await _exportCategoriesPlaintext(exportDb);
        await _exportSettingsPlaintext(exportDb);
        await _exportBudgetsPlaintext(exportDb);
        await _exportAssetsPlaintext(exportDb);
        await _exportRecurringRulesPlaintext(exportDb);
        await _exportSavingsGoalsPlaintext(exportDb);
        await _exportTransactionTemplatesPlaintext(exportDb);
      }
      exportDb.dispose();
      return dbPath;
    } catch (e) {
      exportDb.dispose();
      rethrow;
    }
  }

  /// Export database to CSV format.
  /// Returns a list of paths to the exported files.
  Future<List<String>> exportToCsv(ExportOptions options) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final exportDir = Directory('${tempDir.path}/cachium_csv_$timestamp');
    await exportDir.create();

    final paths = <String>[];

    final transactionsPath = '${exportDir.path}/transactions.csv';
    await _exportTransactionsToCsv(transactionsPath, options);
    paths.add(transactionsPath);

    final accountsPath = '${exportDir.path}/accounts.csv';
    await _exportAccountsToCsv(accountsPath, options);
    paths.add(accountsPath);

    final categoriesPath = '${exportDir.path}/categories.csv';
    await _exportCategoriesToCsv(categoriesPath, options);
    paths.add(categoriesPath);

    final settingsPath = '${exportDir.path}/app_settings.csv';
    await _exportSettingsToCsv(settingsPath);
    paths.add(settingsPath);

    final budgetsPath = '${exportDir.path}/budgets.csv';
    await _exportBudgetsToCsv(budgetsPath, options);
    paths.add(budgetsPath);

    final assetsPath = '${exportDir.path}/assets.csv';
    await _exportAssetsToCsv(assetsPath, options);
    paths.add(assetsPath);

    final recurringRulesPath = '${exportDir.path}/recurring_rules.csv';
    await _exportRecurringRulesToCsv(recurringRulesPath, options);
    paths.add(recurringRulesPath);

    final savingsGoalsPath = '${exportDir.path}/savings_goals.csv';
    await _exportSavingsGoalsToCsv(savingsGoalsPath, options);
    paths.add(savingsGoalsPath);

    final templatesPath = '${exportDir.path}/transaction_templates.csv';
    await _exportTransactionTemplatesToCsv(templatesPath, options);
    paths.add(templatesPath);

    return paths;
  }

  /// Share the exported SQLite file.
  Future<void> shareSqliteExport(String path, {Rect? sharePositionOrigin}) async {
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Cachium Database Export',
      sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
    );
  }

  /// Share the exported CSV files.
  Future<void> shareCsvExport(List<String> paths, {Rect? sharePositionOrigin}) async {
    await Share.shareXFiles(
      paths.map((p) => XFile(p)).toList(),
      subject: 'Cachium CSV Export',
      sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
    );
  }

  // Schema creation methods

  Future<void> _createEncryptedSchema(sql.Database db) async {
    db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        encrypted_blob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        encrypted_blob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        sort_order INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        encrypted_blob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE app_settings (
        id TEXT PRIMARY KEY,
        last_updated_at INTEGER NOT NULL,
        json_data TEXT NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        encrypted_blob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        encrypted_blob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE recurring_rules (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        encrypted_blob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        encrypted_blob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE transaction_templates (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        encrypted_blob BLOB NOT NULL
      )
    ''');
  }

  Future<void> _createPlaintextSchema(sql.Database db) async {
    db.execute('''
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
        date_millis INTEGER NOT NULL,
        created_at_millis INTEGER NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        last_updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0,
        currency_code TEXT NOT NULL DEFAULT 'USD',
        custom_color_value INTEGER,
        custom_icon_code_point INTEGER,
        created_at_millis INTEGER NOT NULL
      )
    ''');

    db.execute('''
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
    ''');

    db.execute('''
      CREATE TABLE app_settings (
        id TEXT PRIMARY KEY,
        last_updated_at INTEGER NOT NULL,
        json_data TEXT NOT NULL
      )
    ''');

    db.execute('''
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
    ''');

    db.execute('''
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
        created_at_millis INTEGER NOT NULL
      )
    ''');

    db.execute('''
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
        frequency TEXT NOT NULL,
        start_date_millis INTEGER NOT NULL,
        end_date_millis INTEGER,
        last_generated_date_millis INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at_millis INTEGER NOT NULL
      )
    ''');

    db.execute('''
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
    ''');

    db.execute('''
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
    ''');
  }

  // Encrypted export methods

  Future<void> _exportTransactionsEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.transactions).get();

    final stmt = exportDb.prepare(
      'INSERT INTO transactions (id, date, last_updated_at, is_deleted, encrypted_blob) VALUES (?, ?, ?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.date,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        row.encryptedBlob,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportAccountsEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.accounts).get();

    final stmt = exportDb.prepare(
      'INSERT INTO accounts (id, created_at, last_updated_at, is_deleted, encrypted_blob) VALUES (?, ?, ?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        row.encryptedBlob,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportCategoriesEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.categories).get();

    final stmt = exportDb.prepare(
      'INSERT INTO categories (id, sort_order, last_updated_at, is_deleted, encrypted_blob) VALUES (?, ?, ?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.sortOrder,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        row.encryptedBlob,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportBudgetsEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.budgets).get();

    final stmt = exportDb.prepare(
      'INSERT INTO budgets (id, created_at, last_updated_at, is_deleted, encrypted_blob) VALUES (?, ?, ?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        row.encryptedBlob,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportAssetsEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.assets).get();

    final stmt = exportDb.prepare(
      'INSERT INTO assets (id, created_at, sort_order, last_updated_at, is_deleted, encrypted_blob) VALUES (?, ?, ?, ?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.createdAt,
        row.sortOrder,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        row.encryptedBlob,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportRecurringRulesEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.recurringRules).get();

    final stmt = exportDb.prepare(
      'INSERT INTO recurring_rules (id, created_at, last_updated_at, is_deleted, encrypted_blob) VALUES (?, ?, ?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        row.encryptedBlob,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportSavingsGoalsEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.savingsGoals).get();

    final stmt = exportDb.prepare(
      'INSERT INTO savings_goals (id, created_at, last_updated_at, is_deleted, encrypted_blob) VALUES (?, ?, ?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        row.encryptedBlob,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportTransactionTemplatesEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.transactionTemplates).get();

    final stmt = exportDb.prepare(
      'INSERT INTO transaction_templates (id, created_at, last_updated_at, is_deleted, encrypted_blob) VALUES (?, ?, ?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        row.encryptedBlob,
      ]);
    }

    stmt.dispose();
  }

  // Plaintext export methods

  Future<void> _exportTransactionsPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.transactions).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO transactions
         (id, date, last_updated_at, is_deleted, amount, category_id, account_id, type, note, currency, conversion_rate, main_currency_code, main_currency_amount, destination_account_id, destination_amount, merchant, asset_id, date_millis, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      final data = TransactionData.fromJson(json);

      stmt.execute([
        row.id,
        row.date,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        data.amount,
        data.categoryId,
        data.accountId,
        data.type,
        data.note,
        data.currency,
        data.conversionRate,
        data.mainCurrencyCode,
        data.mainCurrencyAmount,
        data.destinationAccountId,
        data.destinationAmount,
        data.merchant,
        data.assetId,
        data.dateMillis,
        data.createdAtMillis,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportAccountsPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.accounts).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO accounts
         (id, created_at, last_updated_at, is_deleted, name, type, balance, initial_balance, currency_code, custom_color_value, custom_icon_code_point, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      final data = AccountData.fromJson(json);

      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        data.name,
        data.type,
        data.balance,
        data.initialBalance,
        data.currencyCode,
        data.customColorValue,
        data.customIconCodePoint,
        data.createdAtMillis,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportCategoriesPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.categories).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO categories
         (id, sort_order, last_updated_at, is_deleted, name, icon_code_point, icon_font_family, icon_font_package, color_index, type, is_custom, parent_id, show_assets)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      final data = CategoryData.fromJson(json);

      stmt.execute([
        row.id,
        row.sortOrder,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        data.name,
        data.iconCodePoint,
        data.iconFontFamily,
        data.iconFontPackage,
        data.colorIndex,
        data.type,
        data.isCustom ? 1 : 0,
        data.parentId,
        data.showAssets ? 1 : 0,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportBudgetsPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.budgets).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO budgets
         (id, created_at, last_updated_at, is_deleted, category_id, amount, year, month, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      final data = BudgetData.fromJson(json);

      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        data.categoryId,
        data.amount,
        data.year,
        data.month,
        data.createdAtMillis,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportAssetsPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.assets).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO assets
         (id, created_at, sort_order, last_updated_at, is_deleted, name, icon_code_point, icon_font_family, icon_font_package, color_index, status, note, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      final data = AssetData.fromJson(json);

      stmt.execute([
        row.id,
        row.createdAt,
        row.sortOrder,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        data.name,
        data.iconCodePoint,
        data.iconFontFamily,
        data.iconFontPackage,
        data.colorIndex,
        data.status,
        data.note,
        data.createdAtMillis,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportRecurringRulesPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.recurringRules).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO recurring_rules
         (id, created_at, last_updated_at, is_deleted, name, amount, type, category_id, account_id, destination_account_id, merchant, note, frequency, start_date_millis, end_date_millis, last_generated_date_millis, is_active, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      final data = RecurringRuleData.fromJson(json);

      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        data.name,
        data.amount,
        data.type,
        data.categoryId,
        data.accountId,
        data.destinationAccountId,
        data.merchant,
        data.note,
        data.frequency,
        data.startDateMillis,
        data.endDateMillis,
        data.lastGeneratedDateMillis,
        data.isActive ? 1 : 0,
        data.createdAtMillis,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportSavingsGoalsPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.savingsGoals).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO savings_goals
         (id, created_at, last_updated_at, is_deleted, name, target_amount, current_amount, color_index, icon_code_point, icon_font_family, icon_font_package, linked_account_id, target_date_millis, note, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      final data = SavingsGoalData.fromJson(json);

      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        data.name,
        data.targetAmount,
        data.currentAmount,
        data.colorIndex,
        data.iconCodePoint,
        data.iconFontFamily,
        data.iconFontPackage,
        data.linkedAccountId,
        data.targetDateMillis,
        data.note,
        data.createdAtMillis,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportTransactionTemplatesPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.transactionTemplates).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO transaction_templates
         (id, created_at, last_updated_at, is_deleted, name, amount, type, category_id, account_id, destination_account_id, asset_id, merchant, note, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      final data = TransactionTemplateData.fromJson(json);

      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        data.name,
        data.amount,
        data.type,
        data.categoryId,
        data.accountId,
        data.destinationAccountId,
        data.assetId,
        data.merchant,
        data.note,
        data.createdAtMillis,
      ]);
    }

    stmt.dispose();
  }

  // AppSettings export methods

  Future<void> _exportSettingsEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.appSettings).get();

    final stmt = exportDb.prepare(
      'INSERT INTO app_settings (id, last_updated_at, json_data) VALUES (?, ?, ?)',
    );

    for (final row in rows) {
      stmt.execute([
        row.id,
        row.lastUpdatedAt,
        row.jsonData,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportSettingsPlaintext(sql.Database exportDb) async {
    // Settings are stored as plaintext JSON in both formats
    await _exportSettingsEncrypted(exportDb);
  }

  // CSV export methods

  Future<void> _exportTransactionsToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      final rows = await database.select(database.transactions).get();
      csvData.add(['id', 'date', 'last_updated_at', 'is_deleted', 'encrypted_blob']);

      for (final row in rows) {
        csvData.add([
          row.id,
          row.date,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          base64Encode(row.encryptedBlob),
        ]);
      }
    } else {
      final rows = await database.select(database.transactions).get();
      csvData.add([
        'id', 'date', 'last_updated_at', 'is_deleted', 'amount', 'category_id', 'account_id', 'destination_account_id', 'destination_amount', 'type', 'note', 'merchant', 'currency', 'conversion_rate', 'main_currency_code', 'main_currency_amount', 'asset_id',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = TransactionData.fromJson(json);

        csvData.add([
          row.id,
          row.date,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          data.amount,
          data.categoryId,
          data.accountId,
          data.destinationAccountId ?? '',
          data.destinationAmount ?? '',
          data.type,
          data.note ?? '',
          data.merchant ?? '',
          data.currency,
          data.conversionRate,
          data.mainCurrencyCode,
          data.mainCurrencyAmount ?? '',
          data.assetId ?? '',
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportAccountsToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      final rows = await database.select(database.accounts).get();
      csvData.add(['id', 'created_at', 'last_updated_at', 'is_deleted', 'encrypted_blob']);

      for (final row in rows) {
        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          base64Encode(row.encryptedBlob),
        ]);
      }
    } else {
      final rows = await database.select(database.accounts).get();
      csvData.add([
        'id', 'created_at', 'last_updated_at', 'is_deleted', 'name', 'type', 'balance', 'initial_balance', 'currency_code', 'custom_color_value', 'custom_icon_code_point',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = AccountData.fromJson(json);

        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          data.name,
          data.type,
          data.balance,
          data.initialBalance,
          data.currencyCode,
          data.customColorValue ?? '',
          data.customIconCodePoint ?? '',
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportCategoriesToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      final rows = await database.select(database.categories).get();
      csvData.add(['id', 'sort_order', 'last_updated_at', 'is_deleted', 'encrypted_blob']);

      for (final row in rows) {
        csvData.add([
          row.id,
          row.sortOrder,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          base64Encode(row.encryptedBlob),
        ]);
      }
    } else {
      final rows = await database.select(database.categories).get();
      csvData.add([
        'id', 'sort_order', 'last_updated_at', 'is_deleted', 'name', 'icon_code_point', 'icon_font_family', 'icon_font_package', 'color_index', 'type', 'is_custom', 'parent_id', 'show_assets',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = CategoryData.fromJson(json);

        csvData.add([
          row.id,
          row.sortOrder,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          data.name,
          data.iconCodePoint,
          data.iconFontFamily,
          data.iconFontPackage ?? '',
          data.colorIndex,
          data.type,
          data.isCustom ? 1 : 0,
          data.parentId ?? '',
          data.showAssets ? 1 : 0,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportSettingsToCsv(String path) async {
    final rows = await database.select(database.appSettings).get();
    final List<List<dynamic>> csvData = [];

    csvData.add(['id', 'last_updated_at', 'json_data']);

    for (final row in rows) {
      csvData.add([
        row.id,
        row.lastUpdatedAt,
        row.jsonData,
      ]);
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportBudgetsToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      final rows = await database.select(database.budgets).get();
      csvData.add(['id', 'created_at', 'last_updated_at', 'is_deleted', 'encrypted_blob']);

      for (final row in rows) {
        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          base64Encode(row.encryptedBlob),
        ]);
      }
    } else {
      final rows = await database.select(database.budgets).get();
      csvData.add([
        'id', 'created_at', 'last_updated_at', 'is_deleted', 'category_id', 'amount', 'year', 'month', 'created_at_millis',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = BudgetData.fromJson(json);

        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          data.categoryId,
          data.amount,
          data.year,
          data.month,
          data.createdAtMillis,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportAssetsToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      final rows = await database.select(database.assets).get();
      csvData.add(['id', 'created_at', 'sort_order', 'last_updated_at', 'is_deleted', 'encrypted_blob']);

      for (final row in rows) {
        csvData.add([
          row.id,
          row.createdAt,
          row.sortOrder,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          base64Encode(row.encryptedBlob),
        ]);
      }
    } else {
      final rows = await database.select(database.assets).get();
      csvData.add([
        'id', 'created_at', 'sort_order', 'last_updated_at', 'is_deleted', 'name', 'icon_code_point', 'icon_font_family', 'icon_font_package', 'color_index', 'status', 'note', 'created_at_millis',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = AssetData.fromJson(json);

        csvData.add([
          row.id,
          row.createdAt,
          row.sortOrder,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          data.name,
          data.iconCodePoint,
          data.iconFontFamily ?? '',
          data.iconFontPackage ?? '',
          data.colorIndex,
          data.status,
          data.note ?? '',
          data.createdAtMillis,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportRecurringRulesToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      final rows = await database.select(database.recurringRules).get();
      csvData.add(['id', 'created_at', 'last_updated_at', 'is_deleted', 'encrypted_blob']);

      for (final row in rows) {
        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          base64Encode(row.encryptedBlob),
        ]);
      }
    } else {
      final rows = await database.select(database.recurringRules).get();
      csvData.add([
        'id', 'created_at', 'last_updated_at', 'is_deleted', 'name', 'amount', 'type', 'category_id', 'account_id', 'destination_account_id', 'merchant', 'note', 'frequency', 'start_date_millis', 'end_date_millis', 'last_generated_date_millis', 'is_active', 'created_at_millis',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = RecurringRuleData.fromJson(json);

        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          data.name,
          data.amount,
          data.type,
          data.categoryId,
          data.accountId,
          data.destinationAccountId ?? '',
          data.merchant ?? '',
          data.note ?? '',
          data.frequency,
          data.startDateMillis,
          data.endDateMillis ?? '',
          data.lastGeneratedDateMillis,
          data.isActive ? 1 : 0,
          data.createdAtMillis,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportSavingsGoalsToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      final rows = await database.select(database.savingsGoals).get();
      csvData.add(['id', 'created_at', 'last_updated_at', 'is_deleted', 'encrypted_blob']);

      for (final row in rows) {
        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          base64Encode(row.encryptedBlob),
        ]);
      }
    } else {
      final rows = await database.select(database.savingsGoals).get();
      csvData.add([
        'id', 'created_at', 'last_updated_at', 'is_deleted', 'name', 'target_amount', 'current_amount', 'color_index', 'icon_code_point', 'icon_font_family', 'icon_font_package', 'linked_account_id', 'target_date_millis', 'note', 'created_at_millis',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = SavingsGoalData.fromJson(json);

        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          data.name,
          data.targetAmount,
          data.currentAmount,
          data.colorIndex,
          data.iconCodePoint,
          data.iconFontFamily ?? '',
          data.iconFontPackage ?? '',
          data.linkedAccountId ?? '',
          data.targetDateMillis ?? '',
          data.note ?? '',
          data.createdAtMillis,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportTransactionTemplatesToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      final rows = await database.select(database.transactionTemplates).get();
      csvData.add(['id', 'created_at', 'last_updated_at', 'is_deleted', 'encrypted_blob']);

      for (final row in rows) {
        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          base64Encode(row.encryptedBlob),
        ]);
      }
    } else {
      final rows = await database.select(database.transactionTemplates).get();
      csvData.add([
        'id', 'created_at', 'last_updated_at', 'is_deleted', 'name', 'amount', 'type', 'category_id', 'account_id', 'destination_account_id', 'asset_id', 'merchant', 'note', 'created_at_millis',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = TransactionTemplateData.fromJson(json);

        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          data.name,
          data.amount ?? '',
          data.type,
          data.categoryId ?? '',
          data.accountId ?? '',
          data.destinationAccountId ?? '',
          data.assetId ?? '',
          data.merchant ?? '',
          data.note ?? '',
          data.createdAtMillis,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }
}
