import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../../data/encryption/account_data.dart';
import '../../../data/encryption/category_data.dart';
import '../../../data/encryption/transaction_data.dart';
import '../../../features/settings/data/models/database_metrics.dart';
import '../app_database.dart';
import 'encryption_service.dart';

/// Result of an import operation.
class ImportResult {
  final int transactionsImported;
  final int accountsImported;
  final int categoriesImported;
  final int settingsImported;
  final List<String> errors;

  const ImportResult({
    required this.transactionsImported,
    required this.accountsImported,
    required this.categoriesImported,
    this.settingsImported = 0,
    this.errors = const [],
  });

  int get totalImported => transactionsImported + accountsImported + categoriesImported + settingsImported;
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

  /// Pick a SQLite database file and return its path.
  /// Returns null if the user cancels the file picker.
  Future<String?> pickSqliteFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.first.path;
  }

  /// Pick and import a SQLite database file.
  Future<ImportResult?> pickAndImportSqlite() async {
    final path = await pickSqliteFile();
    if (path == null) {
      return null;
    }

    return importFromSqlite(path);
  }

  /// Clear all existing data and import from a SQLite database file.
  Future<ImportResult> clearAndImportFromSqlite(String path) async {
    // Clear all existing data first
    await database.deleteAllTransactions();
    await database.deleteAllAccounts();
    await database.deleteAllCategories();
    await database.deleteAllSettings();

    // Then import from the file
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

  /// Check if a table uses snake_case column naming (vs camelCase).
  bool _usesSnakeCase(sql.Database db, String tableName) {
    if (!_tableExists(db, tableName)) return true;
    final result = db.select("PRAGMA table_info($tableName)");
    for (final row in result) {
      final colName = row['name'] as String;
      if (colName == 'is_deleted') return true;
      if (colName == 'isDeleted') return false;
    }
    return true; // Default to snake_case
  }

  /// Get metrics from an external SQLite database file.
  DatabaseMetrics getMetricsFromSqliteFile(String path) {
    final importDb = sql.sqlite3.open(path);

    try {
      int transactionCount = 0;
      int categoryCount = 0;
      int accountCount = 0;
      DateTime? oldestRecord;
      DateTime? newestRecord;

      // Count transactions
      if (_tableExists(importDb, 'transactions')) {
        final snakeCase = _usesSnakeCase(importDb, 'transactions');
        final isDeletedCol = snakeCase ? 'is_deleted' : 'isDeleted';
        final lastUpdatedCol = snakeCase ? 'last_updated_at' : 'lastUpdatedAt';

        final result = importDb.select(
          'SELECT COUNT(*) as count FROM transactions WHERE $isDeletedCol = 0',
        );
        if (result.isNotEmpty) {
          transactionCount = result.first['count'] as int? ?? 0;
        }

        // Get oldest transaction date
        final oldestResult = importDb.select(
          'SELECT MIN(date) as oldest FROM transactions WHERE $isDeletedCol = 0',
        );
        if (oldestResult.isNotEmpty && oldestResult.first['oldest'] != null) {
          oldestRecord = DateTime.fromMillisecondsSinceEpoch(
            oldestResult.first['oldest'] as int,
          );
        }

        // Get newest lastUpdatedAt
        final newestResult = importDb.select(
          'SELECT MAX($lastUpdatedCol) as newest FROM transactions',
        );
        if (newestResult.isNotEmpty && newestResult.first['newest'] != null) {
          newestRecord = DateTime.fromMillisecondsSinceEpoch(
            newestResult.first['newest'] as int,
          );
        }
      }

      // Count categories
      if (_tableExists(importDb, 'categories')) {
        final snakeCase = _usesSnakeCase(importDb, 'categories');
        final isDeletedCol = snakeCase ? 'is_deleted' : 'isDeleted';

        final result = importDb.select(
          'SELECT COUNT(*) as count FROM categories WHERE $isDeletedCol = 0',
        );
        if (result.isNotEmpty) {
          categoryCount = result.first['count'] as int? ?? 0;
        }
      }

      // Count accounts
      if (_tableExists(importDb, 'accounts')) {
        final snakeCase = _usesSnakeCase(importDb, 'accounts');
        final isDeletedCol = snakeCase ? 'is_deleted' : 'isDeleted';
        final createdAtCol = snakeCase ? 'created_at' : 'createdAt';

        final result = importDb.select(
          'SELECT COUNT(*) as count FROM accounts WHERE $isDeletedCol = 0',
        );
        if (result.isNotEmpty) {
          accountCount = result.first['count'] as int? ?? 0;
        }

        // Check for older account creation dates
        final accountOldestResult = importDb.select(
          'SELECT MIN($createdAtCol) as oldest FROM accounts WHERE $isDeletedCol = 0',
        );
        if (accountOldestResult.isNotEmpty && accountOldestResult.first['oldest'] != null) {
          final accountOldest = DateTime.fromMillisecondsSinceEpoch(
            accountOldestResult.first['oldest'] as int,
          );
          if (oldestRecord == null || accountOldest.isBefore(oldestRecord)) {
            oldestRecord = accountOldest;
          }
        }
      }

      return DatabaseMetrics(
        transactionCount: transactionCount,
        categoryCount: categoryCount,
        accountCount: accountCount,
        oldestRecord: oldestRecord,
        newestRecord: newestRecord,
      );
    } finally {
      importDb.dispose();
    }
  }

  /// Import data from a SQLite database file.
  Future<ImportResult> importFromSqlite(String path) async {
    final importDb = sql.sqlite3.open(path);
    final errors = <String>[];

    int transactionsImported = 0;
    int accountsImported = 0;
    int categoriesImported = 0;
    int settingsImported = 0;

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

      // Import settings
      if (_tableExists(importDb, 'app_settings')) {
        settingsImported = await _importSettingsFromSqlite(
          importDb,
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
      settingsImported: settingsImported,
      errors: errors,
    );
  }

  /// Import data from CSV files.
  Future<ImportResult> importFromCsv(List<String> paths) async {
    final errors = <String>[];

    int transactionsImported = 0;
    int accountsImported = 0;
    int categoriesImported = 0;
    int settingsImported = 0;

    for (final path in paths) {
      final fileName = path.split('/').last.toLowerCase();

      if (fileName.contains('transaction')) {
        transactionsImported += await _importTransactionsFromCsv(path, errors);
      } else if (fileName.contains('account')) {
        accountsImported += await _importAccountsFromCsv(path, errors);
      } else if (fileName.contains('categor')) {
        categoriesImported += await _importCategoriesFromCsv(path, errors);
      } else if (fileName.contains('settings')) {
        settingsImported += await _importSettingsFromCsv(path, errors);
      }
    }

    return ImportResult(
      transactionsImported: transactionsImported,
      accountsImported: accountsImported,
      categoriesImported: categoriesImported,
      settingsImported: settingsImported,
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
      // Check for both snake_case (actual DB) and camelCase (old exports)
      if (row['name'] == 'encrypted_blob' || row['name'] == 'encryptedBlob') {
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
        // Handle both snake_case (actual DB) and camelCase (old exports)
        final lastUpdatedAt = (row['last_updated_at'] ?? row['lastUpdatedAt']) as int;
        final isDeleted = ((row['is_deleted'] ?? row['isDeleted']) as int) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          // Already encrypted, use directly (handle both naming conventions)
          encryptedBlob = (row['encrypted_blob'] ?? row['encryptedBlob']) as Uint8List;
        } else {
          // Plaintext format, need to encrypt using TransactionData model
          final data = TransactionData(
            id: id,
            amount: ((row['amount']) as num).toDouble(),
            categoryId: (row['category_id'] ?? row['categoryId']) as String,
            accountId: (row['account_id'] ?? row['accountId']) as String,
            type: row['type'] as String,
            note: row['note'] as String?,
            currency: row['currency'] as String? ?? 'USD',
            dateMillis: (row['date_millis'] ?? row['dateMillis'] ?? date) as int,
            createdAtMillis: (row['created_at_millis'] ?? row['createdAtMillis']) as int,
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
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
        // Handle both snake_case and camelCase
        final createdAt = (row['created_at'] ?? row['createdAt']) as int;
        final lastUpdatedAt = (row['last_updated_at'] ?? row['lastUpdatedAt']) as int;
        final isDeleted = ((row['is_deleted'] ?? row['isDeleted']) as int) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = (row['encrypted_blob'] ?? row['encryptedBlob']) as Uint8List;
        } else {
          // Plaintext format, need to encrypt using AccountData model
          final data = AccountData(
            id: id,
            name: row['name'] as String,
            type: row['type'] as String,
            balance: (row['balance'] as num).toDouble(),
            initialBalance: ((row['initial_balance'] ?? row['initialBalance']) as num?)?.toDouble() ?? 0.0,
            customColorValue: (row['custom_color_value'] ?? row['customColorValue']) as int?,
            customIconCodePoint: (row['custom_icon_code_point'] ?? row['customIconCodePoint']) as int?,
            createdAtMillis: (row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt) as int,
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
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
        // Handle both snake_case and camelCase
        final sortOrder = (row['sort_order'] ?? row['sortOrder']) as int;
        final lastUpdatedAt = (row['last_updated_at'] ?? row['lastUpdatedAt']) as int;
        final isDeleted = ((row['is_deleted'] ?? row['isDeleted']) as int) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = (row['encrypted_blob'] ?? row['encryptedBlob']) as Uint8List;
        } else {
          // Plaintext format, need to encrypt using CategoryData model
          final data = CategoryData(
            id: id,
            name: row['name'] as String,
            iconCodePoint: (row['icon_code_point'] ?? row['iconCodePoint']) as int,
            iconFontFamily: (row['icon_font_family'] ?? row['iconFontFamily']) as String,
            iconFontPackage: (row['icon_font_package'] ?? row['iconFontPackage']) as String?,
            colorIndex: (row['color_index'] ?? row['colorIndex']) as int,
            type: row['type'] as String,
            isCustom: ((row['is_custom'] ?? row['isCustom']) as int) == 1,
            parentId: (row['parent_id'] ?? row['parentId']) as String?,
            sortOrder: sortOrder,
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
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
    final hasEncryptedBlob = headers.contains('encrypted_blob') || headers.contains('encryptedBlob');

    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();
        final date = int.parse(data['date'].toString());
        // Handle both snake_case and camelCase
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final isDeleted = (data['is_deleted'] ?? data['isDeleted']).toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          // Plaintext format, need to encrypt using TransactionData model
          final transactionData = TransactionData(
            id: id,
            amount: double.parse(data['amount'].toString()),
            categoryId: (data['category_id'] ?? data['categoryId']).toString(),
            accountId: (data['account_id'] ?? data['accountId']).toString(),
            type: data['type'].toString(),
            note: data['note'].toString().isEmpty ? null : data['note'].toString(),
            currency: data['currency']?.toString() ?? 'USD',
            dateMillis: int.parse((data['date_millis'] ?? data['dateMillis'] ?? date).toString()),
            createdAtMillis: int.parse((data['created_at_millis'] ?? data['createdAtMillis']).toString()),
          );
          encryptedBlob = await encryptionService.encryptJson(transactionData.toJson());
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
    final hasEncryptedBlob = headers.contains('encrypted_blob') || headers.contains('encryptedBlob');

    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();
        // Handle both snake_case and camelCase
        final createdAt = int.parse((data['created_at'] ?? data['createdAt']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final isDeleted = (data['is_deleted'] ?? data['isDeleted']).toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          // Plaintext format, need to encrypt using AccountData model
          final customColorValue = (data['custom_color_value'] ?? data['customColorValue']).toString();
          final customIconCodePoint = (data['custom_icon_code_point'] ?? data['customIconCodePoint']).toString();
          final initialBalanceStr = (data['initial_balance'] ?? data['initialBalance'])?.toString() ?? '0';

          final accountData = AccountData(
            id: id,
            name: data['name'].toString(),
            type: data['type'].toString(),
            balance: double.parse(data['balance'].toString()),
            initialBalance: initialBalanceStr.isEmpty ? 0.0 : double.parse(initialBalanceStr),
            customColorValue: customColorValue.isEmpty ? null : int.parse(customColorValue),
            customIconCodePoint: customIconCodePoint.isEmpty ? null : int.parse(customIconCodePoint),
            createdAtMillis: int.parse((data['created_at_millis'] ?? data['createdAtMillis'] ?? createdAt).toString()),
          );
          encryptedBlob = await encryptionService.encryptJson(accountData.toJson());
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
    final hasEncryptedBlob = headers.contains('encrypted_blob') || headers.contains('encryptedBlob');

    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();
        // Handle both snake_case and camelCase
        final sortOrder = int.parse((data['sort_order'] ?? data['sortOrder']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final isDeleted = (data['is_deleted'] ?? data['isDeleted']).toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          // Plaintext format, need to encrypt using CategoryData model
          final iconFontPackage = (data['icon_font_package'] ?? data['iconFontPackage']).toString();
          final parentId = (data['parent_id'] ?? data['parentId']).toString();

          final categoryData = CategoryData(
            id: id,
            name: data['name'].toString(),
            iconCodePoint: int.parse((data['icon_code_point'] ?? data['iconCodePoint']).toString()),
            iconFontFamily: (data['icon_font_family'] ?? data['iconFontFamily']).toString(),
            iconFontPackage: iconFontPackage.isEmpty ? null : iconFontPackage,
            colorIndex: int.parse((data['color_index'] ?? data['colorIndex']).toString()),
            type: data['type'].toString(),
            isCustom: (data['is_custom'] ?? data['isCustom']).toString() == '1',
            parentId: parentId.isEmpty ? null : parentId,
            sortOrder: sortOrder,
          );
          encryptedBlob = await encryptionService.encryptJson(categoryData.toJson());
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

  // AppSettings import methods

  Future<int> _importSettingsFromSqlite(
    sql.Database importDb,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM app_settings');

    for (final row in rows) {
      try {
        final id = row['id'] as String;
        // Handle both snake_case and camelCase
        final lastUpdatedAt = (row['last_updated_at'] ?? row['lastUpdatedAt']) as int;
        final jsonData = (row['json_data'] ?? row['jsonData']) as String;

        await database.into(database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(
            id: Value(id),
            lastUpdatedAt: Value(lastUpdatedAt),
            jsonData: Value(jsonData),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import settings: $e');
      }
    }

    return count;
  }

  Future<int> _importSettingsFromCsv(String path, List<String> errors) async {
    int count = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return 0;

    final headers = rows.first.map((e) => e.toString()).toList();

    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();
        // Handle both snake_case and camelCase
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final jsonData = (data['json_data'] ?? data['jsonData']).toString();

        await database.into(database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(
            id: Value(id),
            lastUpdatedAt: Value(lastUpdatedAt),
            jsonData: Value(jsonData),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import settings row $i: $e');
      }
    }

    return count;
  }
}
