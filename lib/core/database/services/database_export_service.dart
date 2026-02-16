import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../../data/encryption/account_data.dart';
import '../../../data/encryption/category_data.dart';
import '../../../data/encryption/transaction_data.dart';
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
      } else {
        await _createPlaintextSchema(exportDb);
        await _exportTransactionsPlaintext(exportDb);
        await _exportAccountsPlaintext(exportDb);
        await _exportCategoriesPlaintext(exportDb);
        await _exportSettingsPlaintext(exportDb);
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

  // Plaintext export methods

  Future<void> _exportTransactionsPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.transactions).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO transactions
         (id, date, last_updated_at, is_deleted, amount, category_id, account_id, type, note, currency, date_millis, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
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
         (id, created_at, last_updated_at, is_deleted, name, type, balance, initial_balance, custom_color_value, custom_icon_code_point, created_at_millis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
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
      // Encrypted: include all records (including deleted) for full backup
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
      // Plaintext: skip deleted records for cleaner export
      final rows = await (database.select(database.transactions)
            ..where((t) => t.isDeleted.equals(false)))
          .get();
      csvData.add([
        'id', 'date', 'last_updated_at', 'amount', 'category_id', 'account_id', 'type', 'note', 'currency',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = TransactionData.fromJson(json);

        csvData.add([
          row.id,
          row.date,
          row.lastUpdatedAt,
          data.amount,
          data.categoryId,
          data.accountId,
          data.type,
          data.note ?? '',
          data.currency,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportAccountsToCsv(String path, ExportOptions options) async {
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      // Encrypted: include all records (including deleted) for full backup
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
      // Plaintext: skip deleted records for cleaner export
      final rows = await (database.select(database.accounts)
            ..where((a) => a.isDeleted.equals(false)))
          .get();
      csvData.add([
        'id', 'created_at', 'last_updated_at', 'name', 'type', 'balance', 'initial_balance', 'custom_color_value', 'custom_icon_code_point',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = AccountData.fromJson(json);

        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          data.name,
          data.type,
          data.balance,
          data.initialBalance,
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
      // Encrypted: include all records (including deleted) for full backup
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
      // Plaintext: skip deleted records for cleaner export
      final rows = await (database.select(database.categories)
            ..where((c) => c.isDeleted.equals(false)))
          .get();
      csvData.add([
        'id', 'sort_order', 'last_updated_at', 'name', 'icon_code_point', 'icon_font_family', 'icon_font_package', 'color_index', 'type', 'is_custom', 'parent_id', 'show_assets',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = CategoryData.fromJson(json);

        csvData.add([
          row.id,
          row.sortOrder,
          row.lastUpdatedAt,
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
}
