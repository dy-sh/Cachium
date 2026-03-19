import 'dart:typed_data';

import '../../../exceptions/app_exception.dart';

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

// --- Valid identifier whitelists ---

/// Valid table names that may appear in imported databases.
const validTableNames = {
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
const validColumnNames = {
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
String validateTableName(String name) {
  if (!validTableNames.contains(name)) {
    throw ImportException(
      message: 'Invalid table name: $name',
      code: 'INVALID_IDENTIFIER',
      format: 'sqlite',
    );
  }
  return name;
}

String validateColumnName(String name) {
  if (!validColumnNames.contains(name)) {
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
String safeString(dynamic value, String field, [String? rowId]) {
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
int safeInt(dynamic value, String field, [String? rowId]) {
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
double safeDouble(dynamic value, String field, [String? rowId]) {
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
String? safeStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

/// Safely cast to nullable int.
int? safeIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('Expected int or null, got ${value.runtimeType}: $value');
}

/// Safely cast to nullable double (via num).
double? safeDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw FormatException('Expected num or null, got ${value.runtimeType}: $value');
}

/// Safely cast to Uint8List (for encrypted blobs).
Uint8List safeBlob(dynamic value, String field, [String? rowId]) {
  if (value is Uint8List) return value;
  if (value == null) {
    throw FormatException('Missing required field "$field"${rowId != null ? ' (row $rowId)' : ''}');
  }
  throw FormatException(
    'Expected Uint8List for "$field"${rowId != null ? ' (row $rowId)' : ''}, '
    'got ${value.runtimeType}',
  );
}
