import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../app_database.dart';
import 'encryption_service.dart';

/// Result of an import operation.
class ImportResult {
  final int transactionsImported;
  final int accountsImported;
  final int categoriesImported;
  final List<String> errors;

  const ImportResult({
    required this.transactionsImported,
    required this.accountsImported,
    required this.categoriesImported,
    this.errors = const [],
  });

  int get totalImported => transactionsImported + accountsImported + categoriesImported;
  bool get hasErrors => errors.isNotEmpty;
}

/// Service for importing database data from SQLite or CSV formats.
class DatabaseImportService {
  final AppDatabase database;
  final EncryptionService encryptionService;

  DatabaseImportService({
    required this.database,
    required this.encryptionService,
  });

  /// Pick and import a SQLite database file.
  Future<ImportResult?> pickAndImportSqlite() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final path = result.files.first.path;
    if (path == null) {
      return null;
    }

    return importFromSqlite(path);
  }

  /// Pick and import CSV files.
  Future<ImportResult?> pickAndImportCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final paths = result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();

    if (paths.isEmpty) {
      return null;
    }

    return importFromCsv(paths);
  }

  /// Import data from a SQLite database file.
  Future<ImportResult> importFromSqlite(String path) async {
    final importDb = sql.sqlite3.open(path);
    final errors = <String>[];

    int transactionsImported = 0;
    int accountsImported = 0;
    int categoriesImported = 0;

    try {
      // Detect format by checking for encryptedBlob column
      final isEncrypted = _hasEncryptedBlob(importDb, 'transactions');

      // Import transactions
      if (_tableExists(importDb, 'transactions')) {
        transactionsImported = await _importTransactionsFromSqlite(
          importDb,
          isEncrypted,
          errors,
        );
      }

      // Import accounts
      if (_tableExists(importDb, 'accounts')) {
        accountsImported = await _importAccountsFromSqlite(
          importDb,
          isEncrypted,
          errors,
        );
      }

      // Import categories
      if (_tableExists(importDb, 'categories')) {
        categoriesImported = await _importCategoriesFromSqlite(
          importDb,
          isEncrypted,
          errors,
        );
      }
    } finally {
      importDb.dispose();
    }

    return ImportResult(
      transactionsImported: transactionsImported,
      accountsImported: accountsImported,
      categoriesImported: categoriesImported,
      errors: errors,
    );
  }

  /// Import data from CSV files.
  Future<ImportResult> importFromCsv(List<String> paths) async {
    final errors = <String>[];

    int transactionsImported = 0;
    int accountsImported = 0;
    int categoriesImported = 0;

    for (final path in paths) {
      final fileName = path.split('/').last.toLowerCase();

      if (fileName.contains('transaction')) {
        transactionsImported += await _importTransactionsFromCsv(path, errors);
      } else if (fileName.contains('account')) {
        accountsImported += await _importAccountsFromCsv(path, errors);
      } else if (fileName.contains('categor')) {
        categoriesImported += await _importCategoriesFromCsv(path, errors);
      }
    }

    return ImportResult(
      transactionsImported: transactionsImported,
      accountsImported: accountsImported,
      categoriesImported: categoriesImported,
      errors: errors,
    );
  }

  // Helper methods

  bool _tableExists(sql.Database db, String tableName) {
    final result = db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  bool _hasEncryptedBlob(sql.Database db, String tableName) {
    if (!_tableExists(db, tableName)) {
      return false;
    }

    final result = db.select("PRAGMA table_info($tableName)");
    for (final row in result) {
      if (row['name'] == 'encryptedBlob') {
        return true;
      }
    }
    return false;
  }

  // SQLite import methods

  Future<int> _importTransactionsFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM transactions');

    for (final row in rows) {
      try {
        final id = row['id'] as String;
        final date = row['date'] as int;
        final lastUpdatedAt = row['lastUpdatedAt'] as int;
        final isDeleted = (row['isDeleted'] as int) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          // Already encrypted, use directly
          encryptedBlob = row['encryptedBlob'] as Uint8List;
        } else {
          // Plaintext format, need to encrypt
          final json = {
            'id': id,
            'amount': row['amount'] as double,
            'categoryId': row['categoryId'] as String,
            'accountId': row['accountId'] as String,
            'type': row['type'] as String,
            'note': row['note'] as String?,
            'currency': row['currency'] as String? ?? 'USD',
            'dateMillis': date,
            'createdAtMillis': row['createdAtMillis'] as int,
          };
          encryptedBlob = await encryptionService.encryptJson(json);
        }

        // Insert or update in database
        await database.into(database.transactions).insertOnConflictUpdate(
          TransactionsCompanion(
            id: Value(id),
            date: Value(date),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import transaction: $e');
      }
    }

    return count;
  }

  Future<int> _importAccountsFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM accounts');

    for (final row in rows) {
      try {
        final id = row['id'] as String;
        final createdAt = row['createdAt'] as int;
        final lastUpdatedAt = row['lastUpdatedAt'] as int;
        final isDeleted = (row['isDeleted'] as int) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = row['encryptedBlob'] as Uint8List;
        } else {
          final json = {
            'id': id,
            'name': row['name'] as String,
            'type': row['type'] as String,
            'balance': row['balance'] as double,
            'initialBalance': (row['initialBalance'] as num?)?.toDouble() ?? 0.0,
            'customColorValue': row['customColorValue'] as int?,
            'customIconCodePoint': row['customIconCodePoint'] as int?,
            'createdAtMillis': createdAt,
          };
          encryptedBlob = await encryptionService.encryptJson(json);
        }

        await database.into(database.accounts).insertOnConflictUpdate(
          AccountsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import account: $e');
      }
    }

    return count;
  }

  Future<int> _importCategoriesFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM categories');

    for (final row in rows) {
      try {
        final id = row['id'] as String;
        final sortOrder = row['sortOrder'] as int;
        final lastUpdatedAt = row['lastUpdatedAt'] as int;
        final isDeleted = (row['isDeleted'] as int) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = row['encryptedBlob'] as Uint8List;
        } else {
          final json = {
            'id': id,
            'name': row['name'] as String,
            'iconCodePoint': row['iconCodePoint'] as int,
            'iconFontFamily': row['iconFontFamily'] as String,
            'iconFontPackage': row['iconFontPackage'] as String?,
            'colorIndex': row['colorIndex'] as int,
            'type': row['type'] as String,
            'isCustom': (row['isCustom'] as int) == 1,
            'parentId': row['parentId'] as String?,
            'sortOrder': sortOrder,
          };
          encryptedBlob = await encryptionService.encryptJson(json);
        }

        await database.into(database.categories).insertOnConflictUpdate(
          CategoriesCompanion(
            id: Value(id),
            sortOrder: Value(sortOrder),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import category: $e');
      }
    }

    return count;
  }

  // CSV import methods

  Future<int> _importTransactionsFromCsv(String path, List<String> errors) async {
    int count = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return 0;

    final headers = rows.first.map((e) => e.toString()).toList();
    final hasEncryptedBlob = headers.contains('encryptedBlob');

    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();
        final date = int.parse(data['date'].toString());
        final lastUpdatedAt = int.parse(data['lastUpdatedAt'].toString());
        final isDeleted = data['isDeleted'].toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode(data['encryptedBlob'].toString());
        } else {
          final json = {
            'id': id,
            'amount': double.parse(data['amount'].toString()),
            'categoryId': data['categoryId'].toString(),
            'accountId': data['accountId'].toString(),
            'type': data['type'].toString(),
            'note': data['note'].toString().isEmpty ? null : data['note'].toString(),
            'currency': data['currency']?.toString() ?? 'USD',
            'dateMillis': date,
            'createdAtMillis': int.parse(data['createdAtMillis'].toString()),
          };
          encryptedBlob = await encryptionService.encryptJson(json);
        }

        await database.into(database.transactions).insertOnConflictUpdate(
          TransactionsCompanion(
            id: Value(id),
            date: Value(date),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import transaction row $i: $e');
      }
    }

    return count;
  }

  Future<int> _importAccountsFromCsv(String path, List<String> errors) async {
    int count = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return 0;

    final headers = rows.first.map((e) => e.toString()).toList();
    final hasEncryptedBlob = headers.contains('encryptedBlob');

    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();
        final createdAt = int.parse(data['createdAt'].toString());
        final lastUpdatedAt = int.parse(data['lastUpdatedAt'].toString());
        final isDeleted = data['isDeleted'].toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode(data['encryptedBlob'].toString());
        } else {
          final customColorValue = data['customColorValue'].toString();
          final customIconCodePoint = data['customIconCodePoint'].toString();
          final initialBalanceStr = data['initialBalance']?.toString() ?? '0';

          final json = {
            'id': id,
            'name': data['name'].toString(),
            'type': data['type'].toString(),
            'balance': double.parse(data['balance'].toString()),
            'initialBalance': initialBalanceStr.isEmpty ? 0.0 : double.parse(initialBalanceStr),
            'customColorValue': customColorValue.isEmpty ? null : int.parse(customColorValue),
            'customIconCodePoint': customIconCodePoint.isEmpty ? null : int.parse(customIconCodePoint),
            'createdAtMillis': createdAt,
          };
          encryptedBlob = await encryptionService.encryptJson(json);
        }

        await database.into(database.accounts).insertOnConflictUpdate(
          AccountsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import account row $i: $e');
      }
    }

    return count;
  }

  Future<int> _importCategoriesFromCsv(String path, List<String> errors) async {
    int count = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return 0;

    final headers = rows.first.map((e) => e.toString()).toList();
    final hasEncryptedBlob = headers.contains('encryptedBlob');

    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();
        final sortOrder = int.parse(data['sortOrder'].toString());
        final lastUpdatedAt = int.parse(data['lastUpdatedAt'].toString());
        final isDeleted = data['isDeleted'].toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode(data['encryptedBlob'].toString());
        } else {
          final iconFontPackage = data['iconFontPackage'].toString();
          final parentId = data['parentId'].toString();

          final json = {
            'id': id,
            'name': data['name'].toString(),
            'iconCodePoint': int.parse(data['iconCodePoint'].toString()),
            'iconFontFamily': data['iconFontFamily'].toString(),
            'iconFontPackage': iconFontPackage.isEmpty ? null : iconFontPackage,
            'colorIndex': int.parse(data['colorIndex'].toString()),
            'type': data['type'].toString(),
            'isCustom': data['isCustom'].toString() == '1',
            'parentId': parentId.isEmpty ? null : parentId,
            'sortOrder': sortOrder,
          };
          encryptedBlob = await encryptionService.encryptJson(json);
        }

        await database.into(database.categories).insertOnConflictUpdate(
          CategoriesCompanion(
            id: Value(id),
            sortOrder: Value(sortOrder),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import category row $i: $e');
      }
    }

    return count;
  }
}
