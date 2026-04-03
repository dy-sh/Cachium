import 'dart:io';

import 'package:csv/csv.dart';

import '../../../../core/utils/app_logger.dart';

const _log = AppLogger('CsvValidator');

bool hasColumn(Set<String> headers, String snakeCase, String camelCase) {
  return headers.contains(snakeCase) || headers.contains(camelCase.toLowerCase());
}

Future<String?> validateCsvFile(String path) async {
  try {
    final file = File(path);
    if (!file.existsSync()) {
      return 'File does not exist';
    }

    if (file.lengthSync() == 0) {
      return 'File is empty';
    }

    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) {
      return 'No data found in file';
    }

    if (rows.first.isEmpty) {
      return 'No columns found in header row';
    }

    final headers = rows.first.map((e) => e.toString().toLowerCase()).toSet();

    final fileName = path.split('/').last.toLowerCase();

    if (fileName.contains('transaction_template')) {
      return validateGenericEncryptedCsv(headers, 'Transaction templates');
    } else if (fileName.contains('transaction')) {
      return validateTransactionsCsv(headers);
    } else if (fileName.contains('account')) {
      return validateAccountsCsv(headers);
    } else if (fileName.contains('categor')) {
      return validateCategoriesCsv(headers);
    } else if (fileName.contains('settings')) {
      return validateSettingsCsv(headers);
    } else if (fileName.contains('budget')) {
      return validateGenericEncryptedCsv(headers, 'Budgets');
    } else if (fileName.contains('asset')) {
      return validateGenericEncryptedCsv(headers, 'Assets');
    } else if (fileName.contains('recurring')) {
      return validateGenericEncryptedCsv(headers, 'Recurring rules');
    } else if (fileName.contains('savings') || fileName.contains('goal')) {
      return validateGenericEncryptedCsv(headers, 'Savings goals');
    }

    if (validateTransactionsCsv(headers) == null) return null;
    if (validateAccountsCsv(headers) == null) return null;
    if (validateCategoriesCsv(headers) == null) return null;
    if (validateSettingsCsv(headers) == null) return null;

    return 'Not a recognized Cachium export file';
  } on FormatException catch (e) {
    return 'Invalid CSV format: ${e.message}';
  } catch (e) {
    _log.warning('Could not read CSV file "$path": $e');
    return 'Could not read file';
  }
}

String? validateTransactionsCsv(Set<String> headers) {
  if (hasColumn(headers, 'encrypted_blob', 'encryptedBlob')) {
    final requiredEncrypted = [
      ('id', 'id'),
      ('date', 'date'),
      ('last_updated_at', 'lastUpdatedAt'),
      ('is_deleted', 'isDeleted'),
      ('encrypted_blob', 'encryptedBlob'),
    ];
    final missing = requiredEncrypted
        .where((col) => !hasColumn(headers, col.$1, col.$2))
        .map((col) => col.$1)
        .toList();
    if (missing.isNotEmpty) {
      return 'Transactions file missing columns: ${missing.join(', ')}';
    }
    return null;
  }

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
      .where((col) => !hasColumn(headers, col.$1, col.$2))
      .map((col) => col.$1)
      .toList();
  if (missing.isNotEmpty) {
    return 'Transactions file missing columns: ${missing.join(', ')}';
  }
  return null;
}

String? validateAccountsCsv(Set<String> headers) {
  if (hasColumn(headers, 'encrypted_blob', 'encryptedBlob')) {
    final requiredEncrypted = [
      ('id', 'id'),
      ('created_at', 'createdAt'),
      ('last_updated_at', 'lastUpdatedAt'),
      ('is_deleted', 'isDeleted'),
      ('encrypted_blob', 'encryptedBlob'),
    ];
    final missing = requiredEncrypted
        .where((col) => !hasColumn(headers, col.$1, col.$2))
        .map((col) => col.$1)
        .toList();
    if (missing.isNotEmpty) {
      return 'Accounts file missing columns: ${missing.join(', ')}';
    }
    return null;
  }

  final requiredPlaintext = [
    ('id', 'id'),
    ('created_at', 'createdAt'),
    ('last_updated_at', 'lastUpdatedAt'),
    ('name', 'name'),
    ('type', 'type'),
    ('balance', 'balance'),
  ];
  final missing = requiredPlaintext
      .where((col) => !hasColumn(headers, col.$1, col.$2))
      .map((col) => col.$1)
      .toList();
  if (missing.isNotEmpty) {
    return 'Accounts file missing columns: ${missing.join(', ')}';
  }
  return null;
}

String? validateCategoriesCsv(Set<String> headers) {
  if (hasColumn(headers, 'encrypted_blob', 'encryptedBlob')) {
    final requiredEncrypted = [
      ('id', 'id'),
      ('sort_order', 'sortOrder'),
      ('last_updated_at', 'lastUpdatedAt'),
      ('is_deleted', 'isDeleted'),
      ('encrypted_blob', 'encryptedBlob'),
    ];
    final missing = requiredEncrypted
        .where((col) => !hasColumn(headers, col.$1, col.$2))
        .map((col) => col.$1)
        .toList();
    if (missing.isNotEmpty) {
      return 'Categories file missing columns: ${missing.join(', ')}';
    }
    return null;
  }

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
      .where((col) => !hasColumn(headers, col.$1, col.$2))
      .map((col) => col.$1)
      .toList();
  if (missing.isNotEmpty) {
    return 'Categories file missing columns: ${missing.join(', ')}';
  }
  return null;
}

String? validateGenericEncryptedCsv(Set<String> headers, String tableName) {
  if (!headers.contains('id')) {
    return '$tableName file missing required column: id';
  }
  return null;
}

String? validateSettingsCsv(Set<String> headers) {
  final required = [
    ('id', 'id'),
    ('last_updated_at', 'lastUpdatedAt'),
    ('json_data', 'jsonData'),
  ];
  final missing = required
      .where((col) => !hasColumn(headers, col.$1, col.$2))
      .map((col) => col.$1)
      .toList();
  if (missing.isNotEmpty) {
    return 'Settings file missing columns: ${missing.join(', ')}';
  }
  return null;
}
