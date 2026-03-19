import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../../../data/encryption/account_data.dart';
import '../../../../data/encryption/asset_data.dart';
import '../../../../data/encryption/budget_data.dart';
import '../../../../data/encryption/category_data.dart';
import '../../../../data/encryption/recurring_rule_data.dart';
import '../../../../data/encryption/savings_goal_data.dart';
import '../../../../data/encryption/transaction_data.dart';
import '../../../../data/encryption/transaction_template_data.dart';
import '../../../../features/transactions/data/models/transaction.dart' as tx;
import '../../../../features/settings/data/models/database_metrics.dart';
import '../../../utils/balance_calculation.dart';
import '../../../utils/currency_conversion.dart';
import '../../app_database.dart';
import '../encryption_service.dart';
import 'import_helpers.dart';

class SqliteImporter {
  final AppDatabase database;
  final EncryptionService encryptionService;

  SqliteImporter({
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
    final validationError = validateSqliteFile(path);
    if (validationError != null) {
      return FilePickResult.error(validationError);
    }

    return FilePickResult.success([path]);
  }

  /// Validates that a file is a valid SQLite database.
  /// Returns an error message if invalid, null if valid.
  String? validateSqliteFile(String path) {
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

  /// Check if a table uses snake_case column naming (vs camelCase).
  bool _usesSnakeCase(sql.Database db, String tableName) {
    validateTableName(tableName);
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
        final isDeletedCol = validateColumnName(snakeCase ? 'is_deleted' : 'isDeleted');
        final lastUpdatedCol = validateColumnName(snakeCase ? 'last_updated_at' : 'lastUpdatedAt');

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
        final isDeletedCol = validateColumnName(snakeCase ? 'is_deleted' : 'isDeleted');

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
        final isDeletedCol = validateColumnName(snakeCase ? 'is_deleted' : 'isDeleted');
        final createdAtCol = validateColumnName(snakeCase ? 'created_at' : 'createdAt');

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
    final transactionsSkippedFromValidation = await validateForeignKeys(errors);
    await reconcileAccountBalances(errors);

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
    validateTableName(tableName);
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
        final id = safeString(row['id'], 'id');
        final date = safeInt(row['date'], 'date', id);
        // Handle both snake_case (actual DB) and camelCase (old exports)
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          // Already encrypted, use directly (handle both naming conventions)
          encryptedBlob = safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          // Plaintext format, need to encrypt using TransactionData model
          final conversionRateRaw = row['conversion_rate'] ?? row['conversionRate'];
          final conversionRate = conversionRateRaw != null ? safeDouble(conversionRateRaw, 'conversion_rate', id) : 1.0;
          final amount = safeDouble(row['amount'], 'amount', id);
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
            categoryId: safeString(row['category_id'] ?? row['categoryId'], 'category_id', id),
            accountId: safeString(row['account_id'] ?? row['accountId'], 'account_id', id),
            destinationAccountId: safeStringOrNull(destAccountIdRaw),
            destinationAmount: safeDoubleOrNull(destAmountRaw),
            type: safeString(row['type'], 'type', id),
            note: safeStringOrNull(row['note']),
            merchant: safeStringOrNull(merchantRaw),
            assetId: safeStringOrNull(assetIdRaw),
            currency: safeStringOrNull(row['currency']) ?? 'USD',
            conversionRate: conversionRate,
            mainCurrencyCode: safeStringOrNull(mainCurrencyCodeRaw) ?? 'USD',
            mainCurrencyAmount: safeDoubleOrNull(mainCurrencyAmountRaw),
            dateMillis: safeInt(row['date_millis'] ?? row['dateMillis'] ?? date, 'date_millis', id),
            createdAtMillis: safeInt(row['created_at_millis'] ?? row['createdAtMillis'], 'created_at_millis', id),
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
        final id = safeString(row['id'], 'id');
        // Handle both snake_case and camelCase
        final createdAt = safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final sortOrder = safeInt(row['sort_order'] ?? row['sortOrder'] ?? 0, 'sort_order', id);
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          // Plaintext format, need to encrypt using AccountData model
          final data = AccountData(
            id: id,
            name: safeString(row['name'], 'name', id),
            type: safeString(row['type'], 'type', id),
            balance: safeDouble(row['balance'], 'balance', id),
            initialBalance: safeDoubleOrNull(row['initial_balance'] ?? row['initialBalance']) ?? 0.0,
            customColorValue: safeIntOrNull(row['custom_color_value'] ?? row['customColorValue']),
            customIconCodePoint: safeIntOrNull(row['custom_icon_code_point'] ?? row['customIconCodePoint']),
            customIconFontFamily: safeStringOrNull(row['custom_icon_font_family'] ?? row['customIconFontFamily']),
            customIconFontPackage: safeStringOrNull(row['custom_icon_font_package'] ?? row['customIconFontPackage']),
            currencyCode: safeStringOrNull(row['currency_code'] ?? row['currencyCode']) ?? 'USD',
            createdAtMillis: safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
          );
          encryptedBlob = await encryptionService.encryptJson(data.toJson());
        }

        await database.into(database.accounts).insertOnConflictUpdate(
          AccountsCompanion(
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
        final id = safeString(row['id'], 'id');
        // Handle both snake_case and camelCase
        final sortOrder = safeInt(row['sort_order'] ?? row['sortOrder'], 'sort_order', id);
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          // Plaintext format, need to encrypt using CategoryData model
          final showAssetsRaw = row['show_assets'] ?? row['showAssets'];
          final data = CategoryData(
            id: id,
            name: safeString(row['name'], 'name', id),
            iconCodePoint: safeInt(row['icon_code_point'] ?? row['iconCodePoint'], 'icon_code_point', id),
            iconFontFamily: safeString(row['icon_font_family'] ?? row['iconFontFamily'], 'icon_font_family', id),
            iconFontPackage: safeStringOrNull(row['icon_font_package'] ?? row['iconFontPackage']),
            colorIndex: safeInt(row['color_index'] ?? row['colorIndex'], 'color_index', id),
            type: safeString(row['type'], 'type', id),
            isCustom: (safeInt(row['is_custom'] ?? row['isCustom'] ?? 0, 'is_custom', id)) == 1,
            parentId: safeStringOrNull(row['parent_id'] ?? row['parentId']),
            sortOrder: sortOrder,
            showAssets: showAssetsRaw != null && (safeIntOrNull(showAssetsRaw) ?? 0) == 1,
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

  Future<int> _importSettingsFromSqlite(
    sql.Database importDb,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM app_settings');

    for (final row in rows) {
      try {
        final id = safeString(row['id'], 'id');
        // Handle both snake_case and camelCase
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final jsonData = safeString(row['json_data'] ?? row['jsonData'], 'json_data', id);

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

  Future<int> _importBudgetsFromSqlite(
    sql.Database importDb,
    bool isEncrypted,
    List<String> errors,
  ) async {
    int count = 0;
    final rows = importDb.select('SELECT * FROM budgets');

    for (final row in rows) {
      try {
        final id = safeString(row['id'], 'id');
        final createdAt = safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final data = BudgetData(
            id: id,
            categoryId: safeString(row['category_id'] ?? row['categoryId'], 'category_id', id),
            amount: safeDouble(row['amount'], 'amount', id),
            year: safeInt(row['year'], 'year', id),
            month: safeInt(row['month'], 'month', id),
            createdAtMillis: safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
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
        final id = safeString(row['id'], 'id');
        final createdAt = safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final sortOrder = safeInt(row['sort_order'] ?? row['sortOrder'] ?? 0, 'sort_order', id);
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final data = AssetData(
            id: id,
            name: safeString(row['name'], 'name', id),
            iconCodePoint: safeInt(row['icon_code_point'] ?? row['iconCodePoint'], 'icon_code_point', id),
            iconFontFamily: safeStringOrNull(row['icon_font_family'] ?? row['iconFontFamily']),
            iconFontPackage: safeStringOrNull(row['icon_font_package'] ?? row['iconFontPackage']),
            colorIndex: safeInt(row['color_index'] ?? row['colorIndex'], 'color_index', id),
            status: safeString(row['status'], 'status', id),
            note: safeStringOrNull(row['note']),
            sortOrder: sortOrder,
            createdAtMillis: safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
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
        final id = safeString(row['id'], 'id');
        final createdAt = safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final isActiveRaw = row['is_active'] ?? row['isActive'];
          final destAmountRaw = row['destination_amount'] ?? row['destinationAmount'];
          final data = RecurringRuleData(
            id: id,
            name: safeString(row['name'], 'name', id),
            amount: safeDouble(row['amount'], 'amount', id),
            type: safeString(row['type'], 'type', id),
            categoryId: safeString(row['category_id'] ?? row['categoryId'], 'category_id', id),
            accountId: safeString(row['account_id'] ?? row['accountId'], 'account_id', id),
            destinationAccountId: safeStringOrNull(row['destination_account_id'] ?? row['destinationAccountId']),
            merchant: safeStringOrNull(row['merchant']),
            note: safeStringOrNull(row['note']),
            currencyCode: safeStringOrNull(row['currency_code'] ?? row['currencyCode']) ?? 'USD',
            destinationAmount: safeDoubleOrNull(destAmountRaw),
            frequency: safeString(row['frequency'], 'frequency', id),
            startDateMillis: safeInt(row['start_date_millis'] ?? row['startDateMillis'], 'start_date_millis', id),
            endDateMillis: safeIntOrNull(row['end_date_millis'] ?? row['endDateMillis']),
            lastGeneratedDateMillis: safeInt(row['last_generated_date_millis'] ?? row['lastGeneratedDateMillis'], 'last_generated_date_millis', id),
            isActive: isActiveRaw == null || (safeIntOrNull(isActiveRaw) ?? 1) == 1,
            createdAtMillis: safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
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
        final id = safeString(row['id'], 'id');
        final createdAt = safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final data = SavingsGoalData(
            id: id,
            name: safeString(row['name'], 'name', id),
            targetAmount: safeDouble(row['target_amount'] ?? row['targetAmount'], 'target_amount', id),
            currentAmount: safeDouble(row['current_amount'] ?? row['currentAmount'] ?? 0, 'current_amount', id),
            colorIndex: safeInt(row['color_index'] ?? row['colorIndex'], 'color_index', id),
            iconCodePoint: safeInt(row['icon_code_point'] ?? row['iconCodePoint'], 'icon_code_point', id),
            iconFontFamily: safeStringOrNull(row['icon_font_family'] ?? row['iconFontFamily']),
            iconFontPackage: safeStringOrNull(row['icon_font_package'] ?? row['iconFontPackage']),
            linkedAccountId: safeStringOrNull(row['linked_account_id'] ?? row['linkedAccountId']),
            targetDateMillis: safeIntOrNull(row['target_date_millis'] ?? row['targetDateMillis']),
            note: safeStringOrNull(row['note']),
            createdAtMillis: safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
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
        final id = safeString(row['id'], 'id');
        final createdAt = safeInt(row['created_at'] ?? row['createdAt'], 'created_at', id);
        final lastUpdatedAt = safeInt(row['last_updated_at'] ?? row['lastUpdatedAt'], 'last_updated_at', id);
        final isDeleted = (safeInt(row['is_deleted'] ?? row['isDeleted'] ?? 0, 'is_deleted', id)) == 1;

        Uint8List encryptedBlob;

        if (isEncrypted) {
          encryptedBlob = safeBlob(row['encrypted_blob'] ?? row['encryptedBlob'], 'encrypted_blob', id);
        } else {
          final amountRaw = row['amount'];
          final data = TransactionTemplateData(
            id: id,
            name: safeString(row['name'], 'name', id),
            amount: safeDoubleOrNull(amountRaw),
            type: safeString(row['type'], 'type', id),
            categoryId: safeStringOrNull(row['category_id'] ?? row['categoryId']),
            accountId: safeStringOrNull(row['account_id'] ?? row['accountId']),
            destinationAccountId: safeStringOrNull(row['destination_account_id'] ?? row['destinationAccountId']),
            assetId: safeStringOrNull(row['asset_id'] ?? row['assetId']),
            merchant: safeStringOrNull(row['merchant']),
            note: safeStringOrNull(row['note']),
            createdAtMillis: safeInt(row['created_at_millis'] ?? row['createdAtMillis'] ?? createdAt, 'created_at_millis', id),
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

  /// Validate that imported transactions reference existing accounts and categories.
  /// Soft-deletes orphaned transactions and returns the count of skipped transactions.
  Future<int> validateForeignKeys(List<String> errors) async {
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
  Future<void> reconcileAccountBalances(List<String> errors) async {
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
                sortOrder: Value(row.sortOrder),
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
