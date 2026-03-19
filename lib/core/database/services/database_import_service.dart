import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../../data/encryption/account_data.dart';
import '../../../data/encryption/asset_data.dart';
import '../../../data/encryption/budget_data.dart';
import '../../../data/encryption/category_data.dart';
import '../../../data/encryption/recurring_rule_data.dart';
import '../../../data/encryption/savings_goal_data.dart';
import '../../../data/encryption/transaction_data.dart';
import '../../../data/encryption/transaction_template_data.dart';
import '../../../features/transactions/data/models/transaction.dart' as tx;
import '../../../features/settings/data/models/csv_import_preview.dart';
import '../../../features/settings/data/models/database_metrics.dart';
import '../../exceptions/app_exception.dart';
import '../../utils/balance_calculation.dart';
import '../../utils/currency_conversion.dart';
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
  final int budgetsImported;
  final int assetsImported;
  final int recurringRulesImported;
  final int savingsGoalsImported;
  final int templatesImported;
  final int transactionsSkipped;
  final List<String> errors;

  const ImportResult({
    required this.transactionsImported,
    required this.accountsImported,
    required this.categoriesImported,
    this.settingsImported = 0,
    this.budgetsImported = 0,
    this.assetsImported = 0,
    this.recurringRulesImported = 0,
    this.savingsGoalsImported = 0,
    this.templatesImported = 0,
    this.transactionsSkipped = 0,
    this.errors = const [],
  });

  int get totalImported => transactionsImported + accountsImported + categoriesImported + settingsImported + budgetsImported + assetsImported + recurringRulesImported + savingsGoalsImported + templatesImported;
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

  /// Valid table names that may appear in imported databases.
  static const _validTableNames = {
    'transactions',
    'accounts',
    'categories',
    'budgets',
    'assets',
    'recurring_rules',
    'savings_goals',
    'transaction_templates',
    'app_settings',
  };

  /// Valid column names that may be interpolated into SQL queries.
  static const _validColumnNames = {
    'is_deleted',
    'isDeleted',
    'last_updated_at',
    'lastUpdatedAt',
    'created_at',
    'createdAt',
    'encrypted_blob',
    'encryptedBlob',
    'sort_order',
    'sortOrder',
    'date',
    'id',
    'name',
    'count',
    'oldest',
    'newest',
    'json_data',
    'jsonData',
  };

  /// Validates that an identifier is in the allowed whitelist.
  /// Throws [ImportException] if the identifier is not valid.
  static String _validateTableName(String name) {
    if (!_validTableNames.contains(name)) {
      throw ImportException(
        message: 'Invalid table name: $name',
        code: 'INVALID_IDENTIFIER',
        format: 'sqlite',
      );
    }
    return name;
  }

  static String _validateColumnName(String name) {
    if (!_validColumnNames.contains(name)) {
      throw ImportException(
        message: 'Invalid column name: $name',
        code: 'INVALID_IDENTIFIER',
        format: 'sqlite',
      );
    }
    return name;
  }

  // --- Safe casting helpers for import data ---

  /// Safely cast a dynamic value to String, with descriptive error.
  static String _safeString(dynamic value, String field, [String? rowId]) {
    if (value is String) return value;
    if (value == null) {
      throw FormatException('Missing required field "$field"${rowId != null ? ' (row $rowId)' : ''}');
    }
    throw FormatException(
      'Expected String for "$field"${rowId != null ? ' (row $rowId)' : ''}, '
      'got ${value.runtimeType}: $value',
    );
  }

  /// Safely cast a dynamic value to int, with descriptive error.
  static int _safeInt(dynamic value, String field, [String? rowId]) {
    if (value is int) return value;
    if (value == null) {
      throw FormatException('Missing required field "$field"${rowId != null ? ' (row $rowId)' : ''}');
    }
    throw FormatException(
      'Expected int for "$field"${rowId != null ? ' (row $rowId)' : ''}, '
      'got ${value.runtimeType}: $value',
    );
  }

  /// Safely cast a dynamic value to double (via num), with descriptive error.
  static double _safeDouble(dynamic value, String field, [String? rowId]) {
    if (value is num) return value.toDouble();
    if (value == null) {
      throw FormatException('Missing required field "$field"${rowId != null ? ' (row $rowId)' : ''}');
    }
    throw FormatException(
      'Expected num for "$field"${rowId != null ? ' (row $rowId)' : ''}, '
      'got ${value.runtimeType}: $value',
    );
  }

  /// Safely cast to nullable String.
  static String? _safeStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  /// Safely cast to nullable int.
  static int? _safeIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    throw FormatException('Expected int or null, got ${value.runtimeType}: $value');
  }

  /// Safely cast to nullable double (via num).
  static double? _safeDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw FormatException('Expected num or null, got ${value.runtimeType}: $value');
  }

  /// Safely cast to Uint8List (for encrypted blobs).
  static Uint8List _safeBlob(dynamic value, String field, [String? rowId]) {
    if (value is Uint8List) return value;
    if (value == null) {
      throw FormatException('Missing required field "$field"${rowId != null ? ' (row $rowId)' : ''}');
    }
    throw FormatException(
      'Expected Uint8List for "$field"${rowId != null ? ' (row $rowId)' : ''}, '
      'got ${value.runtimeType}',
    );
  }

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
    await database.deleteAllBudgets();
    await database.deleteAllAssets();
    await database.deleteAllRecurringRules();
    await database.deleteAllSavingsGoals();
    await database.deleteAllTransactionTemplates();

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
    _validateTableName(tableName);
    if (!_tableExists(db, tableName)) return true;
    final result = db.select("PRAGMA table_info('${tableName.replaceAll("'", "''")}')");
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
        final isDeletedCol = _validateColumnName(snakeCase ? 'is_deleted' : 'isDeleted');
        final lastUpdatedCol = _validateColumnName(snakeCase ? 'last_updated_at' : 'lastUpdatedAt');

        final result = importDb.select(
          'SELECT COUNT(*) as count FROM transactions WHERE "$isDeletedCol" = 0',
        );
        if (result.isNotEmpty) {
          transactionCount = result.first['count'] as int? ?? 0;
        }

        // Get oldest transaction date
        final oldestResult = importDb.select(
          'SELECT MIN(date) as oldest FROM transactions WHERE "$isDeletedCol" = 0',
        );
        if (oldestResult.isNotEmpty && oldestResult.first['oldest'] != null) {
          oldestRecord = DateTime.fromMillisecondsSinceEpoch(
            oldestResult.first['oldest'] as int,
          );
        }

        // Get newest lastUpdatedAt
        final newestResult = importDb.select(
          'SELECT MAX("$lastUpdatedCol") as newest FROM transactions',
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
        final isDeletedCol = _validateColumnName(snakeCase ? 'is_deleted' : 'isDeleted');

        final result = importDb.select(
          'SELECT COUNT(*) as count FROM categories WHERE "$isDeletedCol" = 0',
        );
        if (result.isNotEmpty) {
          categoryCount = result.first['count'] as int? ?? 0;
        }
      }

      // Count accounts
      if (_tableExists(importDb, 'accounts')) {
        final snakeCase = _usesSnakeCase(importDb, 'accounts');
        final isDeletedCol = _validateColumnName(snakeCase ? 'is_deleted' : 'isDeleted');
        final createdAtCol = _validateColumnName(snakeCase ? 'created_at' : 'createdAt');

        final result = importDb.select(
          'SELECT COUNT(*) as count FROM accounts WHERE "$isDeletedCol" = 0',
        );
        if (result.isNotEmpty) {
          accountCount = result.first['count'] as int? ?? 0;
        }

        // Check for older account creation dates
        final accountOldestResult = importDb.select(
          'SELECT MIN("$createdAtCol") as oldest FROM accounts WHERE "$isDeletedCol" = 0',
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
    int budgetsImported = 0;
    int assetsImported = 0;
    int recurringRulesImported = 0;
    int savingsGoalsImported = 0;
    int templatesImported = 0;

    try {
      // Detect format by checking for encryptedBlob column
      final isEncrypted = _hasEncryptedBlob(importDb, 'transactions');

      // Wrap all imports in a database transaction for atomicity —
      // if any table import fails critically, all changes are rolled back.
      await database.transaction(() async {
        // Import accounts and categories first (referenced by transactions)
        if (_tableExists(importDb, 'accounts')) {
          accountsImported = await _importAccountsFromSqlite(
            importDb,
            isEncrypted,
            errors,
          );
        }

        if (_tableExists(importDb, 'categories')) {
          categoriesImported = await _importCategoriesFromSqlite(
            importDb,
            isEncrypted,
            errors,
          );
        }

        // Import transactions (depends on accounts and categories)
        if (_tableExists(importDb, 'transactions')) {
          transactionsImported = await _importTransactionsFromSqlite(
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

        // Import budgets
        if (_tableExists(importDb, 'budgets')) {
          final isEncryptedBudgets = _hasEncryptedBlob(importDb, 'budgets');
          budgetsImported = await _importBudgetsFromSqlite(
            importDb,
            isEncryptedBudgets,
            errors,
          );
        }

        // Import assets
        if (_tableExists(importDb, 'assets')) {
          final isEncryptedAssets = _hasEncryptedBlob(importDb, 'assets');
          assetsImported = await _importAssetsFromSqlite(
            importDb,
            isEncryptedAssets,
            errors,
          );
        }

        // Import recurring rules
        if (_tableExists(importDb, 'recurring_rules')) {
          final isEncryptedRules = _hasEncryptedBlob(importDb, 'recurring_rules');
          recurringRulesImported = await _importRecurringRulesFromSqlite(
            importDb,
            isEncryptedRules,
            errors,
          );
        }

        // Import savings goals
        if (_tableExists(importDb, 'savings_goals')) {
          final isEncryptedGoals = _hasEncryptedBlob(importDb, 'savings_goals');
          savingsGoalsImported = await _importSavingsGoalsFromSqlite(
            importDb,
            isEncryptedGoals,
            errors,
          );
        }

        // Import transaction templates
        if (_tableExists(importDb, 'transaction_templates')) {
          final isEncryptedTemplates = _hasEncryptedBlob(importDb, 'transaction_templates');
          templatesImported = await _importTransactionTemplatesFromSqlite(
            importDb,
            isEncryptedTemplates,
            errors,
          );
        }
      });
    } finally {
      importDb.dispose();
    }

    // Validate foreign key references and reconcile balances
    final transactionsSkippedFromValidation = await _validateForeignKeys(errors);
    await _reconcileAccountBalances(errors);

    return ImportResult(
      transactionsImported: transactionsImported - transactionsSkippedFromValidation,
      accountsImported: accountsImported,
      categoriesImported: categoriesImported,
      settingsImported: settingsImported,
      budgetsImported: budgetsImported,
      assetsImported: assetsImported,
      recurringRulesImported: recurringRulesImported,
      savingsGoalsImported: savingsGoalsImported,
      templatesImported: templatesImported,
      transactionsSkipped: transactionsSkippedFromValidation,
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
    int budgetsImported = 0;
    int assetsImported = 0;
    int recurringRulesImported = 0;
    int savingsGoalsImported = 0;
    int templatesImported = 0;

    for (final path in paths) {
      final fileName = path.split('/').last.toLowerCase();

      if (fileName.startsWith('transaction_template') || fileName.contains('_transaction_template')) {
        templatesImported += await _importTransactionTemplatesFromCsv(path, errors);
      } else if (fileName.startsWith('transaction') || fileName.contains('_transaction')) {
        transactionsImported += await _importTransactionsFromCsv(path, errors);
      } else if (fileName.contains('account')) {
        accountsImported += await _importAccountsFromCsv(path, errors);
      } else if (fileName.contains('categor')) {
        categoriesImported += await _importCategoriesFromCsv(path, errors);
      } else if (fileName.contains('settings')) {
        settingsImported += await _importSettingsFromCsv(path, errors);
      } else if (fileName.contains('budget')) {
        budgetsImported += await _importBudgetsFromCsv(path, errors);
      } else if (fileName.contains('asset')) {
        assetsImported += await _importAssetsFromCsv(path, errors);
      } else if (fileName.contains('recurring')) {
        recurringRulesImported += await _importRecurringRulesFromCsv(path, errors);
      } else if (fileName.contains('savings') || fileName.contains('goal')) {
        savingsGoalsImported += await _importSavingsGoalsFromCsv(path, errors);
      }
    }

    // Validate foreign key references and reconcile balances
    final transactionsSkippedFromValidation = await _validateForeignKeys(errors);
    await _reconcileAccountBalances(errors);

    return ImportResult(
      transactionsImported: transactionsImported - transactionsSkippedFromValidation,
      accountsImported: accountsImported,
      categoriesImported: categoriesImported,
      settingsImported: settingsImported,
      budgetsImported: budgetsImported,
      assetsImported: assetsImported,
      recurringRulesImported: recurringRulesImported,
      savingsGoalsImported: savingsGoalsImported,
      templatesImported: templatesImported,
      transactionsSkipped: transactionsSkippedFromValidation,
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
    _validateTableName(tableName);
    if (!_tableExists(db, tableName)) {
      return false;
    }

    final result = db.select("PRAGMA table_info('${tableName.replaceAll("'", "''")}')");
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
        final id = _safeString(row['id'], 'id');
        final date = _safeInt(row['date'], 'date', id);
        // Handle both snake_case (actual DB) and camelCase (old exports)
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (_safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          // Already encrypted, use directly (handle both naming conventions)
          encryptedBlob = _safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          // Plaintext format, need to encrypt using TransactionData model
          final conversionRateRaw = row['conversion_rate'] ?? row['conversionRate'];
          final conversionRate = conversionRateRaw != null ? _safeDouble(conversionRateRaw, 'conversion_rate', id) : 1.0;
          final amount = _safeDouble(row['amount'], 'amount', id);
          final mainCurrencyCodeRaw = row['main_currency_code'] ?? row['mainCurrencyCode'];
          final mainCurrencyAmountRaw = row['main_currency_amount'] ?? row['mainCurrencyAmount'];
          // Parse optional fields (may not exist in old exports)
          final destAccountIdRaw = row['destination_account_id'] ?? row['destinationAccountId'];
          final destAmountRaw = row['destination_amount'] ?? row['destinationAmount'];
          final merchantRaw = row['merchant'];
          final assetIdRaw = row['asset_id'] ?? row['assetId'];

          final data = TransactionData(
            id: id,
            amount: amount,
            categoryId: _safeString(row['category_id'] ?? row['categoryId'], 'category_id', id),
            accountId: _safeString(row['account_id'] ?? row['accountId'], 'account_id', id),
            destinationAccountId: _safeStringOrNull(destAccountIdRaw),
            destinationAmount: _safeDoubleOrNull(destAmountRaw),
            type: _safeString(row['type'], 'type', id),
            note: _safeStringOrNull(row['note']),
            merchant: _safeStringOrNull(merchantRaw),
            assetId: _safeStringOrNull(assetIdRaw),
            currency: _safeStringOrNull(row['currency']) ?? 'USD',
            conversionRate: conversionRate,
            mainCurrencyCode: _safeStringOrNull(mainCurrencyCodeRaw) ?? 'USD',
            mainCurrencyAmount: _safeDoubleOrNull(mainCurrencyAmountRaw),
            dateMillis: _safeInt(row['date_millis'] ?? row['dateMillis'] ?? date, 'date_millis', id),
            createdAtMillis: _safeInt(row['created_at_millis'] ?? row['createdAtMillis'], 'created_at_millis', id),
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
        final id = _safeString(row['id'], 'id');
        // Handle both snake_case and camelCase
        final createdAt = _safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (_safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = _safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          // Plaintext format, need to encrypt using AccountData model
          final data = AccountData(
            id: id,
            name: _safeString(row['name'], 'name', id),
            type: _safeString(row['type'], 'type', id),
            balance: _safeDouble(row['balance'], 'balance', id),
            initialBalance: _safeDoubleOrNull(row['initial_balance'] ?? row['initialBalance']) ?? 0.0,
            customColorValue: _safeIntOrNull(row['custom_color_value'] ?? row['customColorValue']),
            customIconCodePoint: _safeIntOrNull(row['custom_icon_code_point'] ?? row['customIconCodePoint']),
            customIconFontFamily: _safeStringOrNull(row['custom_icon_font_family'] ?? row['customIconFontFamily']),
            customIconFontPackage: _safeStringOrNull(row['custom_icon_font_package'] ?? row['customIconFontPackage']),
            currencyCode: _safeStringOrNull(row['currency_code'] ?? row['currencyCode']) ?? 'USD',
            createdAtMillis: _safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
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
        final id = _safeString(row['id'], 'id');
        // Handle both snake_case and camelCase
        final sortOrder = _safeInt(row['sort_order'] ?? row['sortOrder'], 'sort_order', id);
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (_safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = _safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          // Plaintext format, need to encrypt using CategoryData model
          final showAssetsRaw = row['show_assets'] ?? row['showAssets'];
          final data = CategoryData(
            id: id,
            name: _safeString(row['name'], 'name', id),
            iconCodePoint: _safeInt(row['icon_code_point'] ?? row['iconCodePoint'], 'icon_code_point', id),
            iconFontFamily: _safeString(row['icon_font_family'] ?? row['iconFontFamily'], 'icon_font_family', id),
            iconFontPackage: _safeStringOrNull(row['icon_font_package'] ?? row['iconFontPackage']),
            colorIndex: _safeInt(row['color_index'] ?? row['colorIndex'], 'color_index', id),
            type: _safeString(row['type'], 'type', id),
            isCustom: (_safeInt(row['is_custom'] ?? row['isCustom'] ?? 0, 'is_custom', id)) == 1,
            parentId: _safeStringOrNull(row['parent_id'] ?? row['parentId']),
            sortOrder: sortOrder,
            showAssets: showAssetsRaw != null && (_safeIntOrNull(showAssetsRaw) ?? 0) == 1,
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
        int date;
        try {
          date = int.parse(data['date'].toString());
        } catch (e) {
          errors.add('Row $i: invalid date "${data['date']}"');
          continue;
        }
        // Handle both snake_case and camelCase
        int lastUpdatedAt;
        try {
          lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        } catch (e) {
          errors.add('Row $i: invalid last_updated_at');
          continue;
        }
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

          // Parse merchant - handle empty strings and "null" string
          final merchantRaw = (data['merchant'])?.toString() ?? '';
          final merchant = (merchantRaw.isEmpty || merchantRaw == 'null') ? null : merchantRaw;

          // Parse destination_account_id
          final destAccountIdRaw = (data['destination_account_id'] ?? data['destinationAccountId'])?.toString() ?? '';
          final destinationAccountId = (destAccountIdRaw.isEmpty || destAccountIdRaw == 'null') ? null : destAccountIdRaw;

          // Parse destination_amount
          final destAmountRaw = (data['destination_amount'] ?? data['destinationAmount'])?.toString() ?? '';
          double? destinationAmount;
          if (destAmountRaw.isNotEmpty && destAmountRaw != 'null') {
            try {
              destinationAmount = double.parse(destAmountRaw);
            } catch (e) {
              errors.add('Row $i: invalid destination_amount "$destAmountRaw"');
              continue;
            }
          }

          // Parse asset_id
          final assetIdRaw = (data['asset_id'] ?? data['assetId'])?.toString() ?? '';
          final assetId = (assetIdRaw.isEmpty || assetIdRaw == 'null') ? null : assetIdRaw;

          // Plaintext format, need to encrypt using TransactionData model
          final conversionRateRaw = data['conversion_rate'] ?? data['conversionRate'];
          double conversionRate;
          try {
            conversionRate = conversionRateRaw != null ? double.parse(conversionRateRaw.toString()) : 1.0;
          } catch (e) {
            errors.add('Row $i: invalid conversion_rate "$conversionRateRaw"');
            continue;
          }
          double amount;
          try {
            amount = double.parse(data['amount'].toString()).abs();
          } catch (e) {
            errors.add('Row $i: invalid amount "${data['amount']}"');
            continue;
          }
          final mainCurrencyCodeRaw = data['main_currency_code'] ?? data['mainCurrencyCode'];
          final mainCurrencyAmountRaw = data['main_currency_amount'] ?? data['mainCurrencyAmount'];

          double? parsedMainCurrencyAmount;
          if (mainCurrencyAmountRaw != null && mainCurrencyAmountRaw.toString().isNotEmpty && mainCurrencyAmountRaw.toString() != 'null') {
            try {
              parsedMainCurrencyAmount = double.parse(mainCurrencyAmountRaw.toString());
            } catch (e) {
              errors.add('Row $i: invalid main_currency_amount "$mainCurrencyAmountRaw"');
              continue;
            }
          }

          int parsedDateMillis;
          try {
            parsedDateMillis = dateMillisRaw != null ? int.parse(dateMillisRaw.toString()) : date;
          } catch (e) {
            errors.add('Row $i: invalid date_millis "$dateMillisRaw"');
            continue;
          }

          int parsedCreatedAtMillis;
          try {
            parsedCreatedAtMillis = createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : date;
          } catch (e) {
            errors.add('Row $i: invalid created_at_millis "$createdAtMillisRaw"');
            continue;
          }

          final transactionData = TransactionData(
            id: id,
            amount: amount,
            categoryId: (data['category_id'] ?? data['categoryId']).toString(),
            accountId: (data['account_id'] ?? data['accountId']).toString(),
            destinationAccountId: destinationAccountId,
            destinationAmount: destinationAmount,
            type: data['type'].toString(),
            note: note,
            merchant: merchant,
            assetId: assetId,
            currency: data['currency']?.toString() ?? 'USD',
            conversionRate: conversionRate,
            mainCurrencyCode: mainCurrencyCodeRaw?.toString() ?? 'USD',
            mainCurrencyAmount: parsedMainCurrencyAmount ??
                (data['currency']?.toString() == (mainCurrencyCodeRaw?.toString() ?? 'USD')
                    ? amount
                    : roundCurrency(amount * conversionRate)),
            dateMillis: parsedDateMillis,
            createdAtMillis: parsedCreatedAtMillis,
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

          final currencyCodeStr = (data['currency_code'] ?? data['currencyCode'])?.toString() ?? '';
          final customIconFontFamily = (data['custom_icon_font_family'] ?? data['customIconFontFamily'])?.toString() ?? '';
          final customIconFontPackage = (data['custom_icon_font_package'] ?? data['customIconFontPackage'])?.toString() ?? '';
          final accountData = AccountData(
            id: id,
            name: data['name'].toString(),
            type: data['type'].toString(),
            balance: double.parse(data['balance'].toString()),
            initialBalance: initialBalanceStr.isEmpty ? 0.0 : double.parse(initialBalanceStr),
            customColorValue: customColorValue.isEmpty ? null : int.parse(customColorValue),
            customIconCodePoint: customIconCodePoint.isEmpty ? null : int.parse(customIconCodePoint),
            customIconFontFamily: customIconFontFamily.isEmpty ? null : customIconFontFamily,
            customIconFontPackage: customIconFontPackage.isEmpty ? null : customIconFontPackage,
            currencyCode: currencyCodeStr.isEmpty ? 'USD' : currencyCodeStr,
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
        final id = _safeString(row['id'], 'id');
        // Handle both snake_case and camelCase
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final jsonData = _safeString(row['json_data'] ?? row['jsonData'], 'json_data', id);

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

  // SQLite import methods for 5 additional tables

  Future<int> _importBudgetsFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM budgets');

    for (final row in rows) {
      try {
        final id = _safeString(row['id'], 'id');
        final createdAt = _safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (_safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = _safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final data = BudgetData(
            id: id,
            categoryId: _safeString(row['category_id'] ?? row['categoryId'], 'category_id', id),
            amount: _safeDouble(row['amount'], 'amount', id),
            year: _safeInt(row['year'], 'year', id),
            month: _safeInt(row['month'], 'month', id),
            createdAtMillis: _safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
        }

        await database.into(database.budgets).insertOnConflictUpdate(
          BudgetsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import budget: $e');
      }
    }

    return count;
  }

  Future<int> _importAssetsFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM assets');

    for (final row in rows) {
      try {
        final id = _safeString(row['id'], 'id');
        final createdAt = _safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final sortOrder = _safeInt(row['sort_order'] ?? row['sortOrder'] ?? 0, 'sort_order', id);
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (_safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = _safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final data = AssetData(
            id: id,
            name: _safeString(row['name'], 'name', id),
            iconCodePoint: _safeInt(row['icon_code_point'] ?? row['iconCodePoint'], 'icon_code_point', id),
            iconFontFamily: _safeStringOrNull(row['icon_font_family'] ?? row['iconFontFamily']),
            iconFontPackage: _safeStringOrNull(row['icon_font_package'] ?? row['iconFontPackage']),
            colorIndex: _safeInt(row['color_index'] ?? row['colorIndex'], 'color_index', id),
            status: _safeString(row['status'], 'status', id),
            note: _safeStringOrNull(row['note']),
            sortOrder: sortOrder,
            createdAtMillis: _safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
        }

        await database.into(database.assets).insertOnConflictUpdate(
          AssetsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            sortOrder: Value(sortOrder),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import asset: $e');
      }
    }

    return count;
  }

  Future<int> _importRecurringRulesFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM recurring_rules');

    for (final row in rows) {
      try {
        final id = _safeString(row['id'], 'id');
        final createdAt = _safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (_safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = _safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final isActiveRaw = row['is_active'] ?? row['isActive'];
          final destAmountRaw = row['destination_amount'] ?? row['destinationAmount'];
          final data = RecurringRuleData(
            id: id,
            name: _safeString(row['name'], 'name', id),
            amount: _safeDouble(row['amount'], 'amount', id),
            type: _safeString(row['type'], 'type', id),
            categoryId: _safeString(row['category_id'] ?? row['categoryId'], 'category_id', id),
            accountId: _safeString(row['account_id'] ?? row['accountId'], 'account_id', id),
            destinationAccountId: _safeStringOrNull(row['destination_account_id'] ?? row['destinationAccountId']),
            merchant: _safeStringOrNull(row['merchant']),
            note: _safeStringOrNull(row['note']),
            currencyCode: _safeStringOrNull(row['currency_code'] ?? row['currencyCode']) ?? 'USD',
            destinationAmount: _safeDoubleOrNull(destAmountRaw),
            frequency: _safeString(row['frequency'], 'frequency', id),
            startDateMillis: _safeInt(row['start_date_millis'] ?? row['startDateMillis'], 'start_date_millis', id),
            endDateMillis: _safeIntOrNull(row['end_date_millis'] ?? row['endDateMillis']),
            lastGeneratedDateMillis: _safeInt(row['last_generated_date_millis'] ?? row['lastGeneratedDateMillis'], 'last_generated_date_millis', id),
            isActive: isActiveRaw == null || (_safeIntOrNull(isActiveRaw) ?? 1) == 1,
            createdAtMillis: _safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
        }

        await database.into(database.recurringRules).insertOnConflictUpdate(
          RecurringRulesCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import recurring rule: $e');
      }
    }

    return count;
  }

  Future<int> _importSavingsGoalsFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM savings_goals');

    for (final row in rows) {
      try {
        final id = _safeString(row['id'], 'id');
        final createdAt = _safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (_safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = _safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final data = SavingsGoalData(
            id: id,
            name: _safeString(row['name'], 'name', id),
            targetAmount: _safeDouble(row['target_amount'] ?? row['targetAmount'], 'target_amount', id),
            currentAmount: _safeDouble(row['current_amount'] ?? row['currentAmount'] ?? 0, 'current_amount', id),
            colorIndex: _safeInt(row['color_index'] ?? row['colorIndex'], 'color_index', id),
            iconCodePoint: _safeInt(row['icon_code_point'] ?? row['iconCodePoint'], 'icon_code_point', id),
            iconFontFamily: _safeStringOrNull(row['icon_font_family'] ?? row['iconFontFamily']),
            iconFontPackage: _safeStringOrNull(row['icon_font_package'] ?? row['iconFontPackage']),
            linkedAccountId: _safeStringOrNull(row['linked_account_id'] ?? row['linkedAccountId']),
            targetDateMillis: _safeIntOrNull(row['target_date_millis'] ?? row['targetDateMillis']),
            note: _safeStringOrNull(row['note']),
            createdAtMillis: _safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
        }

        await database.into(database.savingsGoals).insertOnConflictUpdate(
          SavingsGoalsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import savings goal: $e');
      }
    }

    return count;
  }

  Future<int> _importTransactionTemplatesFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM transaction_templates');

    for (final row in rows) {
      try {
        final id = _safeString(row['id'], 'id');
        final createdAt = _safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = _safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (_safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = _safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final amountRaw = row['amount'];
          final data = TransactionTemplateData(
            id: id,
            name: _safeString(row['name'], 'name', id),
            amount: _safeDoubleOrNull(amountRaw),
            type: _safeString(row['type'], 'type', id),
            categoryId: _safeStringOrNull(row['category_id'] ?? row['categoryId']),
            accountId: _safeStringOrNull(row['account_id'] ?? row['accountId']),
            destinationAccountId: _safeStringOrNull(row['destination_account_id'] ?? row['destinationAccountId']),
            assetId: _safeStringOrNull(row['asset_id'] ?? row['assetId']),
            merchant: _safeStringOrNull(row['merchant']),
            note: _safeStringOrNull(row['note']),
            createdAtMillis: _safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
        }

        await database.into(database.transactionTemplates).insertOnConflictUpdate(
          TransactionTemplatesCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import transaction template: $e');
      }
    }

    return count;
  }

  // CSV import methods for 5 additional tables

  Future<int> _importBudgetsFromCsv(String path, List<String> errors) async {
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
        final createdAt = int.parse((data['created_at'] ?? data['createdAt']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];
          final budgetData = BudgetData(
            id: id,
            categoryId: (data['category_id'] ?? data['categoryId']).toString(),
            amount: double.parse(data['amount'].toString()),
            year: int.parse(data['year'].toString()),
            month: int.parse(data['month'].toString()),
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : createdAt,
          );
          encryptedBlob = await encryptionService.encryptJson(budgetData.toJson());
        }

        await database.into(database.budgets).insertOnConflictUpdate(
          BudgetsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import budget row $i: $e');
      }
    }

    return count;
  }

  Future<int> _importAssetsFromCsv(String path, List<String> errors) async {
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
        final createdAt = int.parse((data['created_at'] ?? data['createdAt']).toString());
        final sortOrder = int.parse((data['sort_order'] ?? data['sortOrder'] ?? '0').toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final iconFontFamily = (data['icon_font_family'] ?? data['iconFontFamily'])?.toString() ?? '';
          final iconFontPackage = (data['icon_font_package'] ?? data['iconFontPackage'])?.toString() ?? '';
          final noteRaw = data['note']?.toString() ?? '';
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          final assetData = AssetData(
            id: id,
            name: data['name'].toString(),
            iconCodePoint: int.parse((data['icon_code_point'] ?? data['iconCodePoint']).toString()),
            iconFontFamily: iconFontFamily.isEmpty ? null : iconFontFamily,
            iconFontPackage: iconFontPackage.isEmpty ? null : iconFontPackage,
            colorIndex: int.parse((data['color_index'] ?? data['colorIndex']).toString()),
            status: data['status'].toString(),
            note: (noteRaw.isEmpty || noteRaw == 'null') ? null : noteRaw,
            sortOrder: sortOrder,
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : createdAt,
          );
          encryptedBlob = await encryptionService.encryptJson(assetData.toJson());
        }

        await database.into(database.assets).insertOnConflictUpdate(
          AssetsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            sortOrder: Value(sortOrder),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import asset row $i: $e');
      }
    }

    return count;
  }

  Future<int> _importRecurringRulesFromCsv(String path, List<String> errors) async {
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
        final createdAt = int.parse((data['created_at'] ?? data['createdAt']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final destAccountIdRaw = (data['destination_account_id'] ?? data['destinationAccountId'])?.toString() ?? '';
          final merchantRaw = data['merchant']?.toString() ?? '';
          final noteRaw = data['note']?.toString() ?? '';
          final endDateMillisRaw = (data['end_date_millis'] ?? data['endDateMillis'])?.toString() ?? '';
          final isActiveRaw = (data['is_active'] ?? data['isActive'])?.toString() ?? '1';
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          final currencyCodeRaw = (data['currency_code'] ?? data['currencyCode'])?.toString() ?? '';
          final destAmountRaw = (data['destination_amount'] ?? data['destinationAmount'])?.toString() ?? '';

          final ruleData = RecurringRuleData(
            id: id,
            name: data['name'].toString(),
            amount: double.parse(data['amount'].toString()),
            type: data['type'].toString(),
            categoryId: (data['category_id'] ?? data['categoryId']).toString(),
            accountId: (data['account_id'] ?? data['accountId']).toString(),
            destinationAccountId: (destAccountIdRaw.isEmpty || destAccountIdRaw == 'null') ? null : destAccountIdRaw,
            merchant: (merchantRaw.isEmpty || merchantRaw == 'null') ? null : merchantRaw,
            note: (noteRaw.isEmpty || noteRaw == 'null') ? null : noteRaw,
            currencyCode: currencyCodeRaw.isEmpty ? 'USD' : currencyCodeRaw,
            destinationAmount: (destAmountRaw.isEmpty || destAmountRaw == 'null') ? null : double.parse(destAmountRaw),
            frequency: data['frequency'].toString(),
            startDateMillis: int.parse((data['start_date_millis'] ?? data['startDateMillis']).toString()),
            endDateMillis: (endDateMillisRaw.isEmpty || endDateMillisRaw == 'null') ? null : int.parse(endDateMillisRaw),
            lastGeneratedDateMillis: int.parse((data['last_generated_date_millis'] ?? data['lastGeneratedDateMillis']).toString()),
            isActive: isActiveRaw != '0',
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : createdAt,
          );
          encryptedBlob = await encryptionService.encryptJson(ruleData.toJson());
        }

        await database.into(database.recurringRules).insertOnConflictUpdate(
          RecurringRulesCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import recurring rule row $i: $e');
      }
    }

    return count;
  }

  Future<int> _importSavingsGoalsFromCsv(String path, List<String> errors) async {
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
        final createdAt = int.parse((data['created_at'] ?? data['createdAt']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final iconFontFamily = (data['icon_font_family'] ?? data['iconFontFamily'])?.toString() ?? '';
          final iconFontPackage = (data['icon_font_package'] ?? data['iconFontPackage'])?.toString() ?? '';
          final linkedAccountIdRaw = (data['linked_account_id'] ?? data['linkedAccountId'])?.toString() ?? '';
          final targetDateMillisRaw = (data['target_date_millis'] ?? data['targetDateMillis'])?.toString() ?? '';
          final noteRaw = data['note']?.toString() ?? '';
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          final goalData = SavingsGoalData(
            id: id,
            name: data['name'].toString(),
            targetAmount: double.parse((data['target_amount'] ?? data['targetAmount']).toString()),
            currentAmount: double.parse((data['current_amount'] ?? data['currentAmount'] ?? '0').toString()),
            colorIndex: int.parse((data['color_index'] ?? data['colorIndex']).toString()),
            iconCodePoint: int.parse((data['icon_code_point'] ?? data['iconCodePoint']).toString()),
            iconFontFamily: iconFontFamily.isEmpty ? null : iconFontFamily,
            iconFontPackage: iconFontPackage.isEmpty ? null : iconFontPackage,
            linkedAccountId: (linkedAccountIdRaw.isEmpty || linkedAccountIdRaw == 'null') ? null : linkedAccountIdRaw,
            targetDateMillis: (targetDateMillisRaw.isEmpty || targetDateMillisRaw == 'null') ? null : int.parse(targetDateMillisRaw),
            note: (noteRaw.isEmpty || noteRaw == 'null') ? null : noteRaw,
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : createdAt,
          );
          encryptedBlob = await encryptionService.encryptJson(goalData.toJson());
        }

        await database.into(database.savingsGoals).insertOnConflictUpdate(
          SavingsGoalsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import savings goal row $i: $e');
      }
    }

    return count;
  }

  Future<int> _importTransactionTemplatesFromCsv(String path, List<String> errors) async {
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
        final createdAt = int.parse((data['created_at'] ?? data['createdAt']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final amountRaw = data['amount']?.toString() ?? '';
          final categoryIdRaw = (data['category_id'] ?? data['categoryId'])?.toString() ?? '';
          final accountIdRaw = (data['account_id'] ?? data['accountId'])?.toString() ?? '';
          final destAccountIdRaw = (data['destination_account_id'] ?? data['destinationAccountId'])?.toString() ?? '';
          final assetIdRaw = (data['asset_id'] ?? data['assetId'])?.toString() ?? '';
          final merchantRaw = data['merchant']?.toString() ?? '';
          final noteRaw = data['note']?.toString() ?? '';
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          final templateData = TransactionTemplateData(
            id: id,
            name: data['name'].toString(),
            amount: (amountRaw.isEmpty || amountRaw == 'null') ? null : double.parse(amountRaw),
            type: data['type'].toString(),
            categoryId: (categoryIdRaw.isEmpty || categoryIdRaw == 'null') ? null : categoryIdRaw,
            accountId: (accountIdRaw.isEmpty || accountIdRaw == 'null') ? null : accountIdRaw,
            destinationAccountId: (destAccountIdRaw.isEmpty || destAccountIdRaw == 'null') ? null : destAccountIdRaw,
            assetId: (assetIdRaw.isEmpty || assetIdRaw == 'null') ? null : assetIdRaw,
            merchant: (merchantRaw.isEmpty || merchantRaw == 'null') ? null : merchantRaw,
            note: (noteRaw.isEmpty || noteRaw == 'null') ? null : noteRaw,
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : createdAt,
          );
          encryptedBlob = await encryptionService.encryptJson(templateData.toJson());
        }

        await database.into(database.transactionTemplates).insertOnConflictUpdate(
          TransactionTemplatesCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        count++;
      } catch (e) {
        errors.add('Failed to import template row $i: $e');
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

      if (fileName.contains('transaction_template')) {
        return _validateGenericEncryptedCsv(headers, 'Transaction templates');
      } else if (fileName.contains('transaction')) {
        return _validateTransactionsCsv(headers);
      } else if (fileName.contains('account')) {
        return _validateAccountsCsv(headers);
      } else if (fileName.contains('categor')) {
        return _validateCategoriesCsv(headers);
      } else if (fileName.contains('settings')) {
        return _validateSettingsCsv(headers);
      } else if (fileName.contains('budget')) {
        return _validateGenericEncryptedCsv(headers, 'Budgets');
      } else if (fileName.contains('asset')) {
        return _validateGenericEncryptedCsv(headers, 'Assets');
      } else if (fileName.contains('recurring')) {
        return _validateGenericEncryptedCsv(headers, 'Recurring rules');
      } else if (fileName.contains('savings') || fileName.contains('goal')) {
        return _validateGenericEncryptedCsv(headers, 'Savings goals');
      }

      // If filename doesn't match, try to detect by columns
      if (_validateTransactionsCsv(headers) == null) return null;
      if (_validateAccountsCsv(headers) == null) return null;
      if (_validateCategoriesCsv(headers) == null) return null;
      if (_validateSettingsCsv(headers) == null) return null;

      return 'Not a recognized Cachium export file';
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

  /// Validates a CSV file for tables that use the standard encrypted schema
  /// (id, created_at, last_updated_at, is_deleted, encrypted_blob) or plaintext with id column.
  String? _validateGenericEncryptedCsv(Set<String> headers, String tableName) {
    if (!headers.contains('id')) {
      return '$tableName file missing required column: id';
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

        int date;
        try {
          date = int.parse(data['date'].toString());
        } catch (e) {
          errors.add('Row $i: invalid date "${data['date']}"');
          continue;
        }
        int lastUpdatedAt;
        try {
          lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        } catch (e) {
          errors.add('Row $i: invalid last_updated_at');
          continue;
        }
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

          final conversionRateRaw2 = data['conversion_rate'] ?? data['conversionRate'];
          double conversionRate2;
          try {
            conversionRate2 = conversionRateRaw2 != null ? double.parse(conversionRateRaw2.toString()) : 1.0;
          } catch (e) {
            errors.add('Row $i: invalid conversion_rate "$conversionRateRaw2"');
            continue;
          }
          double amount2;
          try {
            amount2 = double.parse(data['amount'].toString());
          } catch (e) {
            errors.add('Row $i: invalid amount "${data['amount']}"');
            continue;
          }
          final mainCurrencyCodeRaw2 = data['main_currency_code'] ?? data['mainCurrencyCode'];
          final mainCurrencyAmountRaw2 = data['main_currency_amount'] ?? data['mainCurrencyAmount'];

          double? parsedMainCurrencyAmount2;
          if (mainCurrencyAmountRaw2 != null && mainCurrencyAmountRaw2.toString().isNotEmpty && mainCurrencyAmountRaw2.toString() != 'null') {
            try {
              parsedMainCurrencyAmount2 = double.parse(mainCurrencyAmountRaw2.toString());
            } catch (e) {
              errors.add('Row $i: invalid main_currency_amount "$mainCurrencyAmountRaw2"');
              continue;
            }
          }

          int parsedDateMillis2;
          try {
            parsedDateMillis2 = dateMillisRaw != null ? int.parse(dateMillisRaw.toString()) : date;
          } catch (e) {
            errors.add('Row $i: invalid date_millis "$dateMillisRaw"');
            continue;
          }

          int parsedCreatedAtMillis2;
          try {
            parsedCreatedAtMillis2 = createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : date;
          } catch (e) {
            errors.add('Row $i: invalid created_at_millis "$createdAtMillisRaw"');
            continue;
          }

          // Parse merchant - handle empty strings and "null" string
          final merchantRaw2 = (data['merchant'])?.toString() ?? '';
          final merchant2 = (merchantRaw2.isEmpty || merchantRaw2 == 'null') ? null : merchantRaw2;

          // Parse destination_account_id
          final destAccountIdRaw2 = (data['destination_account_id'] ?? data['destinationAccountId'])?.toString() ?? '';
          final destinationAccountId2 = (destAccountIdRaw2.isEmpty || destAccountIdRaw2 == 'null') ? null : destAccountIdRaw2;

          // Parse destination_amount
          final destAmountRaw2 = (data['destination_amount'] ?? data['destinationAmount'])?.toString() ?? '';
          double? destinationAmount2;
          if (destAmountRaw2.isNotEmpty && destAmountRaw2 != 'null') {
            try {
              destinationAmount2 = double.parse(destAmountRaw2);
            } catch (e) {
              errors.add('Row $i: invalid destination_amount "$destAmountRaw2"');
              continue;
            }
          }

          // Parse asset_id
          final assetIdRaw2 = (data['asset_id'] ?? data['assetId'])?.toString() ?? '';
          final assetId2 = (assetIdRaw2.isEmpty || assetIdRaw2 == 'null') ? null : assetIdRaw2;

          final transactionData = TransactionData(
            id: id,
            amount: amount2,
            categoryId: (data['category_id'] ?? data['categoryId']).toString(),
            accountId: (data['account_id'] ?? data['accountId']).toString(),
            destinationAccountId: destinationAccountId2,
            destinationAmount: destinationAmount2,
            type: data['type'].toString(),
            note: note,
            merchant: merchant2,
            assetId: assetId2,
            currency: data['currency']?.toString() ?? 'USD',
            conversionRate: conversionRate2,
            mainCurrencyCode: mainCurrencyCodeRaw2?.toString() ?? 'USD',
            mainCurrencyAmount: parsedMainCurrencyAmount2,
            dateMillis: parsedDateMillis2,
            createdAtMillis: parsedCreatedAtMillis2,
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

  /// Validate that imported transactions reference existing accounts and categories.
  /// Soft-deletes orphaned transactions and returns the count of skipped transactions.
  Future<int> _validateForeignKeys(List<String> errors) async {
    int skipped = 0;

    try {
      // Collect valid account IDs
      final accountRows = await database.select(database.accounts).get();
      final validAccountIds = <String>{};
      for (final row in accountRows) {
        if (!row.isDeleted) {
          validAccountIds.add(row.id);
        }
      }

      // Collect valid category IDs
      final categoryRows = await database.select(database.categories).get();
      final validCategoryIds = <String>{};
      for (final row in categoryRows) {
        if (!row.isDeleted) {
          validCategoryIds.add(row.id);
        }
      }

      // Collect valid asset IDs
      final assetRows = await database.select(database.assets).get();
      final validAssetIds = <String>{};
      for (final row in assetRows) {
        if (!row.isDeleted) {
          validAssetIds.add(row.id);
        }
      }

      // Check transactions for orphaned references
      final transactionRows = await database.select(database.transactions).get();
      for (final row in transactionRows) {
        if (row.isDeleted) continue;
        try {
          final json = await encryptionService.decryptJson(row.encryptedBlob);
          final data = TransactionData.fromJson(json);

          final hasValidAccount = validAccountIds.contains(data.accountId);
          final hasValidCategory = data.categoryId.isEmpty || validCategoryIds.contains(data.categoryId);
          final hasValidDestAccount = data.destinationAccountId == null ||
              data.destinationAccountId!.isEmpty ||
              validAccountIds.contains(data.destinationAccountId);

          // Treat empty destinationAccountId as null for transfers
          final isTransfer = data.type == 'transfer';
          final hasEmptyDestAccount = isTransfer &&
              data.destinationAccountId != null &&
              data.destinationAccountId!.isEmpty;
          final hasOrphanedAsset = data.assetId != null &&
              data.assetId!.isNotEmpty &&
              !validAssetIds.contains(data.assetId);

          if (!hasValidAccount || !hasValidCategory || !hasValidDestAccount || hasEmptyDestAccount) {
            final reasons = <String>[];
            if (!hasValidAccount) reasons.add('account "${data.accountId}" not found');
            if (!hasValidCategory) reasons.add('category "${data.categoryId}" not found');
            if (!hasValidDestAccount) reasons.add('destination account "${data.destinationAccountId}" not found');
            if (hasEmptyDestAccount) reasons.add('transfer missing destination account');

            errors.add('Skipped transaction ${data.id}: ${reasons.join(', ')}');

            // Soft-delete the orphaned transaction
            await (database.update(database.transactions)
                  ..where((t) => t.id.equals(row.id)))
                .write(const TransactionsCompanion(isDeleted: Value(true)));
            skipped++;
          } else if (hasOrphanedAsset) {
            // Asset is optional — clear it instead of deleting the transaction
            final cleanedData = data.copyWith(assetId: null);
            final encryptedBlob = await encryptionService.encryptJson(cleanedData.toJson());
            await (database.update(database.transactions)
                  ..where((t) => t.id.equals(row.id)))
                .write(TransactionsCompanion(encryptedBlob: Value(encryptedBlob)));
            errors.add('Cleared orphaned asset "${data.assetId}" from transaction ${data.id}');
          }
        } catch (e) {
          errors.add('Skipped corrupted transaction ${row.id}: $e');
        }
      }
    } catch (e) {
      errors.add('Foreign key validation error: $e');
    }

    return skipped;
  }

  /// Recalculate and fix account balances from transaction history after import.
  ///
  /// For each account, computes expectedBalance = initialBalance + deltas,
  /// and updates the stored balance if it differs. Adds warnings for mismatches.
  Future<void> _reconcileAccountBalances(List<String> errors) async {
    try {
      // Decrypt all accounts
      final accountRows = await database.select(database.accounts).get();
      final transactionRows = await database.select(database.transactions).get();

      // Decrypt transactions
      final transactions = <tx.Transaction>[];
      for (final row in transactionRows) {
        if (row.isDeleted) continue;
        try {
          final json = await encryptionService.decryptJson(row.encryptedBlob);
          final data = TransactionData.fromJson(json);
          transactions.add(tx.Transaction(
            id: data.id,
            amount: data.amount,
            type: tx.TransactionType.values.firstWhere(
              (t) => t.name == data.type,
              orElse: () => tx.TransactionType.expense,
            ),
            categoryId: data.categoryId,
            accountId: data.accountId,
            destinationAccountId: data.destinationAccountId,
            destinationAmount: data.destinationAmount,
            currencyCode: data.currency,
            conversionRate: data.conversionRate,
            mainCurrencyCode: data.mainCurrencyCode,
            mainCurrencyAmount: data.mainCurrencyAmount,
            date: DateTime.fromMillisecondsSinceEpoch(data.dateMillis),
            createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
          ));
        } catch (e) {
          errors.add('Skipped corrupted transaction during reconciliation ${row.id}: $e');
        }
      }

      final deltas = calculateAccountDeltas(transactions);

      for (final row in accountRows) {
        if (row.isDeleted) continue;
        try {
          final json = await encryptionService.decryptJson(row.encryptedBlob);
          final data = AccountData.fromJson(json);
          final delta = deltas[data.id] ?? 0;
          final expectedBalance = roundCurrency(data.initialBalance + delta);

          if ((data.balance - expectedBalance).abs() > 0.001) {
            errors.add(
              'Account "${data.name}" balance adjusted: '
              '${data.balance} -> $expectedBalance',
            );

            // Update the account with corrected balance
            final corrected = AccountData(
              id: data.id,
              name: data.name,
              type: data.type,
              balance: expectedBalance,
              initialBalance: data.initialBalance,
              customColorValue: data.customColorValue,
              customIconCodePoint: data.customIconCodePoint,
              customIconFontFamily: data.customIconFontFamily,
              customIconFontPackage: data.customIconFontPackage,
              currencyCode: data.currencyCode,
              createdAtMillis: data.createdAtMillis,
            );
            final encryptedBlob =
                await encryptionService.encryptJson(corrected.toJson());

            await database.into(database.accounts).insertOnConflictUpdate(
              AccountsCompanion(
                id: Value(row.id),
                createdAt: Value(row.createdAt),
                lastUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                isDeleted: Value(row.isDeleted),
                encryptedBlob: Value(encryptedBlob),
              ),
            );
          }
        } catch (_) {
          // Skip corrupted accounts
        }
      }
    } catch (e) {
      errors.add('Balance reconciliation failed: $e');
    }
  }
}
