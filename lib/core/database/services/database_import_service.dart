import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../../data/encryption/account_data.dart';
import '../../../data/encryption/category_data.dart';
import '../../../data/encryption/transaction_data.dart';
import '../../../features/settings/data/models/csv_import_preview.dart';
import '../../../features/settings/data/models/database_metrics.dart';
import '../app_database.dart';
import 'encryption_service.dart';

/// Result of a file pick operation with validation.
class FilePickResult {
  final List<String>? paths;
  final String? error;

  const FilePickResult.success(this.paths) : error = null;
  const FilePickResult.error(this.error) : paths = null;

  bool get isSuccess => paths != null && error == null;
  bool get isError => error != null;
  bool get isCancelled => paths == null && error == null;
}

/// Result of an import operation.
class ImportResult {
  final int transactionsImported;
  final int accountsImported;
  final int categoriesImported;
  final int settingsImported;
  final int transactionsSkipped;
  final List<String> errors;

  const ImportResult({
    required this.transactionsImported,
    required this.accountsImported,
    required this.categoriesImported,
    this.settingsImported = 0,
    this.transactionsSkipped = 0,
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
  /// Returns FilePickResult with path, error, or cancelled state.
  Future<FilePickResult> pickSqliteFile() async {
    // Use FileType.any because iOS/macOS doesn't properly support
    // filtering for .db files. We validate the file after selection.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return const FilePickResult.success(null); // Cancelled
    }

    final path = result.files.first.path;
    if (path == null) {
      return const FilePickResult.error('Could not access selected file');
    }

    // Validate file extension
    final extension = path.split('.').last.toLowerCase();
    if (!['db', 'sqlite', 'sqlite3'].contains(extension)) {
      return const FilePickResult.error('Invalid file type. Please select a .db, .sqlite, or .sqlite3 file');
    }

    // Validate it's a valid SQLite database
    final validationError = _validateSqliteFile(path);
    if (validationError != null) {
      return FilePickResult.error(validationError);
    }

    return FilePickResult.success([path]);
  }

  /// Validates that a file is a valid SQLite database.
  /// Returns an error message if invalid, null if valid.
  String? _validateSqliteFile(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return 'File does not exist';
      }

      // Check file size (SQLite files should be at least 100 bytes for header)
      if (file.lengthSync() < 100) {
        return 'File is too small to be a valid SQLite database';
      }

      // Try to open as SQLite database
      final db = sql.sqlite3.open(path, mode: sql.OpenMode.readOnly);
      try {
        // Try a simple query to verify it's a valid database
        db.select('SELECT 1');
        return null; // Valid
      } finally {
        db.dispose();
      }
    } on sql.SqliteException catch (e) {
      return 'Invalid SQLite database: ${e.message}';
    } catch (e) {
      return 'Could not read file: $e';
    }
  }

  /// Pick and import a SQLite database file.
  /// Returns null if user cancels or validation fails.
  Future<ImportResult?> pickAndImportSqlite() async {
    final result = await pickSqliteFile();
    if (!result.isSuccess || result.paths == null || result.paths!.isEmpty) {
      return null;
    }

    return importFromSqlite(result.paths!.first);
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
          final showAssetsRaw = row['show_assets'] ?? row['showAssets'];
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
            showAssets: showAssetsRaw != null && (showAssetsRaw as int) == 1,
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
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          // Handle optional fields that may not exist in plaintext CSV exports
          final dateMillisRaw = data['date_millis'] ?? data['dateMillis'];
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          // Parse note - handle empty strings and "null" string
          final noteRaw = data['note']?.toString() ?? '';
          final note = (noteRaw.isEmpty || noteRaw == 'null') ? null : noteRaw;

          // Plaintext format, need to encrypt using TransactionData model
          final transactionData = TransactionData(
            id: id,
            amount: double.parse(data['amount'].toString()),
            categoryId: (data['category_id'] ?? data['categoryId']).toString(),
            accountId: (data['account_id'] ?? data['accountId']).toString(),
            type: data['type'].toString(),
            note: note,
            currency: data['currency']?.toString() ?? 'USD',
            // Fall back to 'date' if date_millis not present
            dateMillis: dateMillisRaw != null ? int.parse(dateMillisRaw.toString()) : date,
            // Fall back to 'date' if created_at_millis not present
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : date,
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
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          // Plaintext format, need to encrypt using AccountData model
          final customColorValue = (data['custom_color_value'] ?? data['customColorValue'])?.toString() ?? '';
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
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          // Plaintext format, need to encrypt using CategoryData model
          final iconFontPackage = (data['icon_font_package'] ?? data['iconFontPackage'])?.toString() ?? '';
          final parentId = (data['parent_id'] ?? data['parentId'])?.toString() ?? '';
          final showAssetsRaw = (data['show_assets'] ?? data['showAssets'])?.toString() ?? '';

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
            showAssets: showAssetsRaw == '1',
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

  // CSV Preview and Skip Duplicates methods

  /// Pick CSV files and return their paths.
  /// Returns FilePickResult with paths, error, or cancelled state.
  Future<FilePickResult> pickCsvFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return const FilePickResult.success(null); // Cancelled
    }

    final paths = result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();

    if (paths.isEmpty) {
      return const FilePickResult.error('Could not access selected files');
    }

    // Validate each file
    for (final path in paths) {
      // Validate file extension
      final extension = path.split('.').last.toLowerCase();
      if (extension != 'csv') {
        final fileName = path.split('/').last;
        return FilePickResult.error('Invalid file type: $fileName. Please select only .csv files');
      }

      // Validate it's a valid CSV file
      final validationError = await _validateCsvFile(path);
      if (validationError != null) {
        final fileName = path.split('/').last;
        return FilePickResult.error('Invalid CSV file "$fileName": $validationError');
      }
    }

    return FilePickResult.success(paths);
  }

  /// Validates that a file is a valid CSV file with all required columns.
  /// Returns an error message if invalid, null if valid.
  Future<String?> _validateCsvFile(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return 'File does not exist';
      }

      // Check file size (should have at least a header row)
      if (file.lengthSync() == 0) {
        return 'File is empty';
      }

      // Try to parse as CSV
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) {
        return 'No data found in file';
      }

      // Check if it has a header row with at least one column
      if (rows.first.isEmpty) {
        return 'No columns found in header row';
      }

      // Get headers (normalize to handle both snake_case and camelCase)
      final headers = rows.first.map((e) => e.toString().toLowerCase()).toSet();

      // Determine file type and validate required columns
      final fileName = path.split('/').last.toLowerCase();

      if (fileName.contains('transaction')) {
        return _validateTransactionsCsv(headers);
      } else if (fileName.contains('account')) {
        return _validateAccountsCsv(headers);
      } else if (fileName.contains('categor')) {
        return _validateCategoriesCsv(headers);
      } else if (fileName.contains('settings')) {
        return _validateSettingsCsv(headers);
      }

      // If filename doesn't match, try to detect by columns
      if (_validateTransactionsCsv(headers) == null) return null;
      if (_validateAccountsCsv(headers) == null) return null;
      if (_validateCategoriesCsv(headers) == null) return null;
      if (_validateSettingsCsv(headers) == null) return null;

      return 'Not a recognized Cachium export file. File name should contain "transaction", "account", "categor", or "settings"';
    } on FormatException catch (e) {
      return 'Invalid CSV format: ${e.message}';
    } catch (e) {
      return 'Could not read file';
    }
  }

  /// Check if headers contain a column (handles snake_case and camelCase).
  bool _hasColumn(Set<String> headers, String snakeCase, String camelCase) {
    return headers.contains(snakeCase) || headers.contains(camelCase.toLowerCase());
  }

  /// Validates transactions CSV has all required columns.
  String? _validateTransactionsCsv(Set<String> headers) {
    // Check for encrypted format first
    if (_hasColumn(headers, 'encrypted_blob', 'encryptedBlob')) {
      final requiredEncrypted = [
        ('id', 'id'),
        ('date', 'date'),
        ('last_updated_at', 'lastUpdatedAt'),
        ('is_deleted', 'isDeleted'),
        ('encrypted_blob', 'encryptedBlob'),
      ];
      final missing = requiredEncrypted
          .where((col) => !_hasColumn(headers, col.$1, col.$2))
          .map((col) => col.$1)
          .toList();
      if (missing.isNotEmpty) {
        return 'Transactions file missing columns: ${missing.join(', ')}';
      }
      return null;
    }

    // Plaintext format (is_deleted is optional - defaults to false when missing)
    final requiredPlaintext = [
      ('id', 'id'),
      ('date', 'date'),
      ('last_updated_at', 'lastUpdatedAt'),
      ('amount', 'amount'),
      ('category_id', 'categoryId'),
      ('account_id', 'accountId'),
      ('type', 'type'),
      ('currency', 'currency'),
    ];
    final missing = requiredPlaintext
        .where((col) => !_hasColumn(headers, col.$1, col.$2))
        .map((col) => col.$1)
        .toList();
    if (missing.isNotEmpty) {
      return 'Transactions file missing columns: ${missing.join(', ')}';
    }
    return null;
  }

  /// Validates accounts CSV has all required columns.
  String? _validateAccountsCsv(Set<String> headers) {
    // Check for encrypted format first
    if (_hasColumn(headers, 'encrypted_blob', 'encryptedBlob')) {
      final requiredEncrypted = [
        ('id', 'id'),
        ('created_at', 'createdAt'),
        ('last_updated_at', 'lastUpdatedAt'),
        ('is_deleted', 'isDeleted'),
        ('encrypted_blob', 'encryptedBlob'),
      ];
      final missing = requiredEncrypted
          .where((col) => !_hasColumn(headers, col.$1, col.$2))
          .map((col) => col.$1)
          .toList();
      if (missing.isNotEmpty) {
        return 'Accounts file missing columns: ${missing.join(', ')}';
      }
      return null;
    }

    // Plaintext format (is_deleted is optional - defaults to false when missing)
    final requiredPlaintext = [
      ('id', 'id'),
      ('created_at', 'createdAt'),
      ('last_updated_at', 'lastUpdatedAt'),
      ('name', 'name'),
      ('type', 'type'),
      ('balance', 'balance'),
    ];
    final missing = requiredPlaintext
        .where((col) => !_hasColumn(headers, col.$1, col.$2))
        .map((col) => col.$1)
        .toList();
    if (missing.isNotEmpty) {
      return 'Accounts file missing columns: ${missing.join(', ')}';
    }
    return null;
  }

  /// Validates categories CSV has all required columns.
  String? _validateCategoriesCsv(Set<String> headers) {
    // Check for encrypted format first
    if (_hasColumn(headers, 'encrypted_blob', 'encryptedBlob')) {
      final requiredEncrypted = [
        ('id', 'id'),
        ('sort_order', 'sortOrder'),
        ('last_updated_at', 'lastUpdatedAt'),
        ('is_deleted', 'isDeleted'),
        ('encrypted_blob', 'encryptedBlob'),
      ];
      final missing = requiredEncrypted
          .where((col) => !_hasColumn(headers, col.$1, col.$2))
          .map((col) => col.$1)
          .toList();
      if (missing.isNotEmpty) {
        return 'Categories file missing columns: ${missing.join(', ')}';
      }
      return null;
    }

    // Plaintext format (is_deleted is optional - defaults to false when missing)
    final requiredPlaintext = [
      ('id', 'id'),
      ('sort_order', 'sortOrder'),
      ('last_updated_at', 'lastUpdatedAt'),
      ('name', 'name'),
      ('icon_code_point', 'iconCodePoint'),
      ('icon_font_family', 'iconFontFamily'),
      ('color_index', 'colorIndex'),
      ('type', 'type'),
      ('is_custom', 'isCustom'),
    ];
    final missing = requiredPlaintext
        .where((col) => !_hasColumn(headers, col.$1, col.$2))
        .map((col) => col.$1)
        .toList();
    if (missing.isNotEmpty) {
      return 'Categories file missing columns: ${missing.join(', ')}';
    }
    return null;
  }

  /// Validates settings CSV has all required columns.
  String? _validateSettingsCsv(Set<String> headers) {
    final required = [
      ('id', 'id'),
      ('last_updated_at', 'lastUpdatedAt'),
      ('json_data', 'jsonData'),
    ];
    final missing = required
        .where((col) => !_hasColumn(headers, col.$1, col.$2))
        .map((col) => col.$1)
        .toList();
    if (missing.isNotEmpty) {
      return 'Settings file missing columns: ${missing.join(', ')}';
    }
    return null;
  }

  /// Generate a preview of what will be imported from CSV files.
  /// This parses the files without actually importing anything.
  Future<CsvImportPreview> generateCsvPreview(List<String> paths) async {
    final fileStatuses = <CsvFileStatus>[];
    int transactionCount = 0;
    int accountCount = 0;
    int categoryCount = 0;
    int settingsCount = 0;

    // Track IDs from CSV files
    final csvTransactionIds = <String>{};
    final csvCategoryIds = <String>{};
    final csvAccountIds = <String>{};

    // Track referenced IDs from transactions
    final referencedCategoryIds = <String>{};
    final referencedAccountIds = <String>{};

    // Parse each file
    for (final path in paths) {
      final fileName = path.split('/').last.toLowerCase();
      final content = await File(path).readAsString();
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) continue;

      final headers = rows.first.map((e) => e.toString()).toList();
      final recordCount = rows.length - 1; // Exclude header row

      if (fileName.contains('transaction')) {
        transactionCount = recordCount;
        fileStatuses.add(CsvFileStatus(
          type: CsvFileType.transactions,
          isSelected: true,
          filePath: path,
          recordCount: recordCount,
        ));

        // Extract transaction IDs and referenced category/account IDs
        final idIndex = headers.indexOf('id');
        final categoryIdIndex = _findColumnIndex(headers, ['category_id', 'categoryId']);
        final accountIdIndex = _findColumnIndex(headers, ['account_id', 'accountId']);

        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (idIndex >= 0 && idIndex < row.length) {
            csvTransactionIds.add(row[idIndex].toString());
          }
          if (categoryIdIndex >= 0 && categoryIdIndex < row.length) {
            referencedCategoryIds.add(row[categoryIdIndex].toString());
          }
          if (accountIdIndex >= 0 && accountIdIndex < row.length) {
            referencedAccountIds.add(row[accountIdIndex].toString());
          }
        }
      } else if (fileName.contains('account')) {
        accountCount = recordCount;
        fileStatuses.add(CsvFileStatus(
          type: CsvFileType.accounts,
          isSelected: true,
          filePath: path,
          recordCount: recordCount,
        ));

        // Extract account IDs
        final idIndex = headers.indexOf('id');
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (idIndex >= 0 && idIndex < row.length) {
            csvAccountIds.add(row[idIndex].toString());
          }
        }
      } else if (fileName.contains('categor')) {
        categoryCount = recordCount;
        fileStatuses.add(CsvFileStatus(
          type: CsvFileType.categories,
          isSelected: true,
          filePath: path,
          recordCount: recordCount,
        ));

        // Extract category IDs
        final idIndex = headers.indexOf('id');
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (idIndex >= 0 && idIndex < row.length) {
            csvCategoryIds.add(row[idIndex].toString());
          }
        }
      } else if (fileName.contains('settings')) {
        settingsCount = recordCount;
        fileStatuses.add(CsvFileStatus(
          type: CsvFileType.settings,
          isSelected: true,
          filePath: path,
          recordCount: recordCount,
        ));
      }
    }

    // Add unselected file types
    final selectedTypes = fileStatuses.map((s) => s.type).toSet();
    for (final type in CsvFileType.values) {
      if (!selectedTypes.contains(type)) {
        fileStatuses.add(CsvFileStatus(
          type: type,
          isSelected: false,
        ));
      }
    }

    // Sort by enum order
    fileStatuses.sort((a, b) => a.type.index.compareTo(b.type.index));

    // Get existing IDs from database
    final existingTransactionIds = await _getExistingTransactionIds();
    final existingCategoryIds = await _getExistingCategoryIds();
    final existingAccountIds = await _getExistingAccountIds();

    // Calculate duplicates for all types
    final duplicateTransactionIds = csvTransactionIds.intersection(existingTransactionIds);
    final duplicateTransactionCount = duplicateTransactionIds.length;
    final newTransactionCount = transactionCount - duplicateTransactionCount;

    final duplicateAccountIds = csvAccountIds.intersection(existingAccountIds);
    final duplicateAccountCount = duplicateAccountIds.length;
    final newAccountCount = accountCount - duplicateAccountCount;

    final duplicateCategoryIds = csvCategoryIds.intersection(existingCategoryIds);
    final duplicateCategoryCount = duplicateCategoryIds.length;
    final newCategoryCount = categoryCount - duplicateCategoryCount;

    // Calculate missing references (IDs referenced by transactions but not in CSV or DB)
    final allAvailableCategoryIds = csvCategoryIds.union(existingCategoryIds);
    final allAvailableAccountIds = csvAccountIds.union(existingAccountIds);

    final missingCategoryIds = referencedCategoryIds.difference(allAvailableCategoryIds);
    final missingAccountIds = referencedAccountIds.difference(allAvailableAccountIds);

    return CsvImportPreview(
      fileStatuses: fileStatuses,
      transactionCount: transactionCount,
      accountCount: accountCount,
      categoryCount: categoryCount,
      settingsCount: settingsCount,
      duplicateTransactionCount: duplicateTransactionCount,
      duplicateAccountCount: duplicateAccountCount,
      duplicateCategoryCount: duplicateCategoryCount,
      newTransactionCount: newTransactionCount,
      newAccountCount: newAccountCount,
      newCategoryCount: newCategoryCount,
      missingCategoryIds: missingCategoryIds,
      missingAccountIds: missingAccountIds,
      filePaths: paths,
    );
  }

  /// Import from CSV files, skipping duplicates.
  Future<ImportResult> importFromCsvWithSkipDuplicates(List<String> paths) async {
    final errors = <String>[];

    int transactionsImported = 0;
    int transactionsSkipped = 0;
    int accountsImported = 0;
    int accountsSkipped = 0;
    int categoriesImported = 0;
    int categoriesSkipped = 0;
    int settingsImported = 0;

    // Get existing IDs to skip duplicates
    final existingTransactionIds = await _getExistingTransactionIds();
    final existingAccountIds = await _getExistingAccountIds();
    final existingCategoryIds = await _getExistingCategoryIds();

    for (final path in paths) {
      final fileName = path.split('/').last.toLowerCase();

      if (fileName.contains('transaction')) {
        final result = await _importTransactionsFromCsvSkipDuplicates(
          path,
          existingTransactionIds,
          errors,
        );
        transactionsImported += result.imported;
        transactionsSkipped += result.skipped;
      } else if (fileName.contains('account')) {
        final result = await _importAccountsFromCsvSkipDuplicates(
          path,
          existingAccountIds,
          errors,
        );
        accountsImported += result.imported;
        accountsSkipped += result.skipped;
      } else if (fileName.contains('categor')) {
        final result = await _importCategoriesFromCsvSkipDuplicates(
          path,
          existingCategoryIds,
          errors,
        );
        categoriesImported += result.imported;
        categoriesSkipped += result.skipped;
      } else if (fileName.contains('settings')) {
        settingsImported += await _importSettingsFromCsv(path, errors);
      }
    }

    final totalSkipped = transactionsSkipped + accountsSkipped + categoriesSkipped;

    return ImportResult(
      transactionsImported: transactionsImported,
      accountsImported: accountsImported,
      categoriesImported: categoriesImported,
      settingsImported: settingsImported,
      transactionsSkipped: totalSkipped,
      errors: errors,
    );
  }

  // Helper methods for CSV preview

  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      final index = headers.indexOf(name);
      if (index >= 0) return index;
    }
    return -1;
  }

  Future<Set<String>> _getExistingTransactionIds() async {
    final result = await database.select(database.transactions).get();
    return result.map((t) => t.id).toSet();
  }

  Future<Set<String>> _getExistingCategoryIds() async {
    final result = await database.select(database.categories).get();
    return result.map((c) => c.id).toSet();
  }

  Future<Set<String>> _getExistingAccountIds() async {
    final result = await database.select(database.accounts).get();
    return result.map((a) => a.id).toSet();
  }

  Future<({int imported, int skipped})> _importTransactionsFromCsvSkipDuplicates(
    String path,
    Set<String> existingIds,
    List<String> errors,
  ) async {
    int imported = 0;
    int skipped = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return (imported: 0, skipped: 0);

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

        // Skip if transaction already exists
        if (existingIds.contains(id)) {
          skipped++;
          continue;
        }

        final date = int.parse(data['date'].toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          // Handle optional fields that may not exist in plaintext CSV exports
          final dateMillisRaw = data['date_millis'] ?? data['dateMillis'];
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          // Parse note - handle empty strings and "null" string
          final noteRaw = data['note']?.toString() ?? '';
          final note = (noteRaw.isEmpty || noteRaw == 'null') ? null : noteRaw;

          final transactionData = TransactionData(
            id: id,
            amount: double.parse(data['amount'].toString()),
            categoryId: (data['category_id'] ?? data['categoryId']).toString(),
            accountId: (data['account_id'] ?? data['accountId']).toString(),
            type: data['type'].toString(),
            note: note,
            currency: data['currency']?.toString() ?? 'USD',
            // Fall back to 'date' if date_millis not present
            dateMillis: dateMillisRaw != null ? int.parse(dateMillisRaw.toString()) : date,
            // Fall back to 'date' if created_at_millis not present
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : date,
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
        imported++;
      } catch (e) {
        errors.add('Failed to import transaction row $i: $e');
      }
    }

    return (imported: imported, skipped: skipped);
  }

  Future<({int imported, int skipped})> _importAccountsFromCsvSkipDuplicates(
    String path,
    Set<String> existingIds,
    List<String> errors,
  ) async {
    int imported = 0;
    int skipped = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return (imported: 0, skipped: 0);

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

        // Skip if account already exists
        if (existingIds.contains(id)) {
          skipped++;
          continue;
        }

        final createdAt = int.parse((data['created_at'] ?? data['createdAt']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final customColorValue = (data['custom_color_value'] ?? data['customColorValue'])?.toString() ?? '';
          final customIconCodePoint = (data['custom_icon_code_point'] ?? data['customIconCodePoint'])?.toString() ?? '';
          final initialBalanceStr = (data['initial_balance'] ?? data['initialBalance'])?.toString() ?? '0';
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          final accountData = AccountData(
            id: id,
            name: data['name'].toString(),
            type: data['type'].toString(),
            balance: double.parse(data['balance'].toString()),
            initialBalance: initialBalanceStr.isEmpty ? 0.0 : double.parse(initialBalanceStr),
            customColorValue: customColorValue.isEmpty ? null : int.parse(customColorValue),
            customIconCodePoint: customIconCodePoint.isEmpty ? null : int.parse(customIconCodePoint),
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : createdAt,
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
        imported++;
      } catch (e) {
        errors.add('Failed to import account row $i: $e');
      }
    }

    return (imported: imported, skipped: skipped);
  }

  Future<({int imported, int skipped})> _importCategoriesFromCsvSkipDuplicates(
    String path,
    Set<String> existingIds,
    List<String> errors,
  ) async {
    int imported = 0;
    int skipped = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return (imported: 0, skipped: 0);

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

        // Skip if category already exists
        if (existingIds.contains(id)) {
          skipped++;
          continue;
        }

        final sortOrder = int.parse((data['sort_order'] ?? data['sortOrder']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final iconFontPackage = (data['icon_font_package'] ?? data['iconFontPackage'])?.toString() ?? '';
          final parentId = (data['parent_id'] ?? data['parentId'])?.toString() ?? '';
          final showAssetsRaw = (data['show_assets'] ?? data['showAssets'])?.toString() ?? '';

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
            showAssets: showAssetsRaw == '1',
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
        imported++;
      } catch (e) {
        errors.add('Failed to import category row $i: $e');
      }
    }

    return (imported: imported, skipped: skipped);
  }
}
