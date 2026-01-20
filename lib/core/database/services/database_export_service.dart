import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

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
      } else {
        await _createPlaintextSchema(exportDb);
        await _exportTransactionsPlaintext(exportDb);
        await _exportAccountsPlaintext(exportDb);
        await _exportCategoriesPlaintext(exportDb);
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

    return paths;
  }

  /// Share the exported SQLite file.
  Future<void> shareSqliteExport(String path) async {
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Cachium Database Export',
    );
  }

  /// Share the exported CSV files.
  Future<void> shareCsvExport(List<String> paths) async {
    await Share.shareXFiles(
      paths.map((p) => XFile(p)).toList(),
      subject: 'Cachium CSV Export',
    );
  }

  // Schema creation methods

  Future<void> _createEncryptedSchema(sql.Database db) async {
    db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        lastUpdatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        encryptedBlob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        createdAt INTEGER NOT NULL,
        lastUpdatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        encryptedBlob BLOB NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        sortOrder INTEGER NOT NULL,
        lastUpdatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        encryptedBlob BLOB NOT NULL
      )
    ''');
  }

  Future<void> _createPlaintextSchema(sql.Database db) async {
    db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        lastUpdatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        amount REAL NOT NULL,
        categoryId TEXT NOT NULL,
        accountId TEXT NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        currency TEXT NOT NULL DEFAULT 'USD',
        createdAtMillis INTEGER NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        createdAt INTEGER NOT NULL,
        lastUpdatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        customColorValue INTEGER,
        customIconCodePoint INTEGER
      )
    ''');

    db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        sortOrder INTEGER NOT NULL,
        lastUpdatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        iconFontFamily TEXT NOT NULL,
        iconFontPackage TEXT,
        colorIndex INTEGER NOT NULL,
        type TEXT NOT NULL,
        isCustom INTEGER NOT NULL DEFAULT 0,
        parentId TEXT
      )
    ''');
  }

  // Encrypted export methods

  Future<void> _exportTransactionsEncrypted(sql.Database exportDb) async {
    final rows = await database.select(database.transactions).get();

    final stmt = exportDb.prepare(
      'INSERT INTO transactions (id, date, lastUpdatedAt, isDeleted, encryptedBlob) VALUES (?, ?, ?, ?, ?)',
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
      'INSERT INTO accounts (id, createdAt, lastUpdatedAt, isDeleted, encryptedBlob) VALUES (?, ?, ?, ?, ?)',
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
      'INSERT INTO categories (id, sortOrder, lastUpdatedAt, isDeleted, encryptedBlob) VALUES (?, ?, ?, ?, ?)',
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
         (id, date, lastUpdatedAt, isDeleted, amount, categoryId, accountId, type, note, currency, createdAtMillis)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      stmt.execute([
        row.id,
        row.date,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        (json['amount'] as num).toDouble(),
        json['categoryId'] as String,
        json['accountId'] as String,
        json['type'] as String,
        json['note'] as String?,
        json['currency'] as String? ?? 'USD',
        json['createdAtMillis'] as int,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportAccountsPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.accounts).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO accounts
         (id, createdAt, lastUpdatedAt, isDeleted, name, type, balance, customColorValue, customIconCodePoint)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      stmt.execute([
        row.id,
        row.createdAt,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        json['name'] as String,
        json['type'] as String,
        (json['balance'] as num).toDouble(),
        json['customColorValue'] as int?,
        json['customIconCodePoint'] as int?,
      ]);
    }

    stmt.dispose();
  }

  Future<void> _exportCategoriesPlaintext(sql.Database exportDb) async {
    final rows = await database.select(database.categories).get();

    final stmt = exportDb.prepare(
      '''INSERT INTO categories
         (id, sortOrder, lastUpdatedAt, isDeleted, name, iconCodePoint, iconFontFamily, iconFontPackage, colorIndex, type, isCustom, parentId)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    );

    for (final row in rows) {
      final json = await encryptionService.decryptJson(row.encryptedBlob);
      stmt.execute([
        row.id,
        row.sortOrder,
        row.lastUpdatedAt,
        row.isDeleted ? 1 : 0,
        json['name'] as String,
        json['iconCodePoint'] as int,
        json['iconFontFamily'] as String,
        json['iconFontPackage'] as String?,
        json['colorIndex'] as int,
        json['type'] as String,
        (json['isCustom'] as bool? ?? false) ? 1 : 0,
        json['parentId'] as String?,
      ]);
    }

    stmt.dispose();
  }

  // CSV export methods

  Future<void> _exportTransactionsToCsv(String path, ExportOptions options) async {
    final rows = await database.select(database.transactions).get();
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      csvData.add(['id', 'date', 'lastUpdatedAt', 'isDeleted', 'encryptedBlob']);

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
      csvData.add([
        'id', 'date', 'lastUpdatedAt', 'isDeleted',
        'amount', 'categoryId', 'accountId', 'type', 'note', 'currency', 'createdAtMillis',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        csvData.add([
          row.id,
          row.date,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          json['amount'],
          json['categoryId'],
          json['accountId'],
          json['type'],
          json['note'] ?? '',
          json['currency'] ?? 'USD',
          json['createdAtMillis'],
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportAccountsToCsv(String path, ExportOptions options) async {
    final rows = await database.select(database.accounts).get();
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      csvData.add(['id', 'createdAt', 'lastUpdatedAt', 'isDeleted', 'encryptedBlob']);

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
      csvData.add([
        'id', 'createdAt', 'lastUpdatedAt', 'isDeleted',
        'name', 'type', 'balance', 'customColorValue', 'customIconCodePoint',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        csvData.add([
          row.id,
          row.createdAt,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          json['name'],
          json['type'],
          json['balance'],
          json['customColorValue'] ?? '',
          json['customIconCodePoint'] ?? '',
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }

  Future<void> _exportCategoriesToCsv(String path, ExportOptions options) async {
    final rows = await database.select(database.categories).get();
    final List<List<dynamic>> csvData = [];

    if (options.encryptionEnabled) {
      csvData.add(['id', 'sortOrder', 'lastUpdatedAt', 'isDeleted', 'encryptedBlob']);

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
      csvData.add([
        'id', 'sortOrder', 'lastUpdatedAt', 'isDeleted',
        'name', 'iconCodePoint', 'iconFontFamily', 'iconFontPackage',
        'colorIndex', 'type', 'isCustom', 'parentId',
      ]);

      for (final row in rows) {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        csvData.add([
          row.id,
          row.sortOrder,
          row.lastUpdatedAt,
          row.isDeleted ? 1 : 0,
          json['name'],
          json['iconCodePoint'],
          json['iconFontFamily'],
          json['iconFontPackage'] ?? '',
          json['colorIndex'],
          json['type'],
          (json['isCustom'] as bool? ?? false) ? 1 : 0,
          json['parentId'] ?? '',
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(csvData);
    await File(path).writeAsString(csv);
  }
}
