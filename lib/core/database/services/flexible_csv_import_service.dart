import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../features/accounts/data/models/account.dart';
import '../../../features/categories/data/models/category.dart';
import '../../../features/settings/data/models/flexible_csv_import_config.dart';
import '../../../features/settings/data/models/flexible_csv_import_state.dart';
import '../../../features/transactions/data/models/transaction.dart';

/// Service for flexible CSV import with custom column mappings.
class FlexibleCsvImportService {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;

  static const _uuid = Uuid();

  FlexibleCsvImportService({
    required this.transactionRepository,
    required this.accountRepository,
    required this.categoryRepository,
  });

  /// Load and parse a CSV file, returning headers and rows.
  Future<({List<String> headers, List<List<dynamic>> rows})?> loadCsvFile(
    String path,
  ) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) return null;

      final headers = rows.first.map((e) => e.toString()).toList();
      final dataRows = rows.skip(1).toList();

      return (headers: headers, rows: dataRows);
    } catch (e) {
      return null;
    }
  }

  /// Auto-detect column mappings based on header names.
  Map<String, FieldMapping> autoDetectMappings(
    ImportEntityType entityType,
    List<String> csvHeaders,
  ) {
    final fields = ImportFieldDefinitions.getFieldsForType(entityType);
    final mappings = <String, FieldMapping>{};

    for (final field in fields) {
      String? matchedColumn;

      // Try to find a matching header
      for (final header in csvHeaders) {
        if (_headersMatch(header, field.key)) {
          matchedColumn = header;
          break;
        }
      }

      mappings[field.key] = FieldMapping(
        fieldKey: field.key,
        csvColumn: matchedColumn,
        missingStrategy: field.isId
            ? MissingFieldStrategy.generateId
            : (field.defaultValue != null
                ? MissingFieldStrategy.useDefault
                : MissingFieldStrategy.skip),
        fkStrategy: field.isForeignKey
            ? ForeignKeyMatchStrategy.byName
            : null,
        defaultValue: field.defaultValue,
      );
    }

    return mappings;
  }

  /// Check if a CSV header matches a field key (case-insensitive, ignoring separators).
  bool _headersMatch(String header, String fieldKey) {
    final normalizedHeader = _normalizeColumnName(header);
    final normalizedKey = _normalizeColumnName(fieldKey);

    // Direct match
    if (normalizedHeader == normalizedKey) return true;

    // Common aliases
    final aliases = _getFieldAliases(fieldKey);
    for (final alias in aliases) {
      if (normalizedHeader == _normalizeColumnName(alias)) return true;
    }

    return false;
  }

  String _normalizeColumnName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');
  }

  List<String> _getFieldAliases(String fieldKey) {
    switch (fieldKey) {
      case 'id':
        return ['uuid', 'identifier', 'transaction_id', 'account_id', 'category_id'];
      case 'amount':
        return ['value', 'sum', 'price', 'cost', 'total'];
      case 'categoryId':
        return ['category', 'cat', 'category_name', 'cat_id'];
      case 'accountId':
        return ['account', 'acc', 'account_name', 'acc_id'];
      case 'date':
        return ['transaction_date', 'txn_date', 'datetime', 'timestamp'];
      case 'note':
        return ['description', 'memo', 'comment', 'notes', 'details'];
      case 'type':
        return ['transaction_type', 'category_type', 'account_type', 'kind'];
      case 'name':
        return ['title', 'label', 'display_name'];
      case 'balance':
        return ['current_balance', 'bal', 'amount'];
      case 'initialBalance':
        return ['initial_balance', 'starting_balance', 'opening_balance'];
      case 'colorIndex':
        return ['color_index', 'color', 'colour'];
      case 'icon':
        return ['icon_code', 'icon_code_point'];
      case 'createdAt':
        return ['created_at', 'created', 'creation_date', 'created_at_millis'];
      default:
        return [];
    }
  }

  /// Parse and validate CSV data according to the config.
  Future<ParseResult> parseAndValidate(
    FlexibleCsvImportConfig config,
    Map<String, Category> categoriesById,
    Map<String, Category> categoriesByName,
    Map<String, Account> accountsById,
    Map<String, Account> accountsByName,
    String? defaultCategoryId,
    String? defaultAccountId,
  ) async {
    final validRows = <ParsedImportRow>[];
    final invalidRows = <ParsedImportRow>[];
    final globalErrors = <String>[];
    final categoriesToCreate = <String>{};
    final accountsToCreate = <String>{};

    final fields = ImportFieldDefinitions.getFieldsForType(config.entityType);

    for (int i = 0; i < config.csvRows.length; i++) {
      final row = config.csvRows[i];
      final errors = <String>[];
      final warnings = <String>[];
      final parsedValues = <String, dynamic>{};

      for (final field in fields) {
        final mapping = config.fieldMappings[field.key];
        if (mapping == null) continue;

        dynamic rawValue;

        // Get raw value from CSV
        if (mapping.csvColumn != null) {
          final colIndex = config.csvHeaders.indexOf(mapping.csvColumn!);
          if (colIndex >= 0 && colIndex < row.length) {
            rawValue = row[colIndex];
          }
        }

        // Handle missing values
        if (rawValue == null || rawValue.toString().trim().isEmpty || rawValue.toString() == 'null') {
          if (field.isRequired) {
            if (field.isId && mapping.missingStrategy == MissingFieldStrategy.generateId) {
              parsedValues[field.key] = _uuid.v4();
            } else if (mapping.missingStrategy == MissingFieldStrategy.useDefault && field.defaultValue != null) {
              parsedValues[field.key] = field.defaultValue;
            } else if (mapping.defaultValue != null) {
              parsedValues[field.key] = mapping.defaultValue;
            } else {
              errors.add('Missing required field: ${field.displayName}');
            }
          }
          continue;
        }

        // Parse the value based on type
        try {
          final parsed = _parseValue(
            rawValue.toString(),
            field.type,
            field.key,
          );

          // Handle foreign key resolution
          if (field.isForeignKey && parsed != null) {
            final resolvedId = _resolveForeignKey(
              parsed.toString(),
              field.foreignKeyEntity!,
              mapping.fkStrategy ?? ForeignKeyMatchStrategy.byName,
              categoriesById,
              categoriesByName,
              accountsById,
              accountsByName,
              defaultCategoryId,
              defaultAccountId,
            );

            if (resolvedId == null) {
              if (mapping.fkStrategy == ForeignKeyMatchStrategy.createIfMissing) {
                // Track for creation
                if (field.foreignKeyEntity == 'category') {
                  categoriesToCreate.add(parsed.toString());
                } else if (field.foreignKeyEntity == 'account') {
                  accountsToCreate.add(parsed.toString());
                }
                parsedValues[field.key] = 'CREATE:${parsed.toString()}';
              } else {
                errors.add('Could not resolve ${field.displayName}: $parsed');
              }
            } else {
              parsedValues[field.key] = resolvedId;
            }
          } else {
            parsedValues[field.key] = parsed;
          }
        } catch (e) {
          errors.add('Invalid ${field.displayName}: $rawValue');
        }
      }

      final parsedRow = ParsedImportRow(
        rowIndex: i + 1, // 1-based for display
        parsedValues: parsedValues,
        errors: errors,
        warnings: warnings,
      );

      if (parsedRow.isValid) {
        validRows.add(parsedRow);
      } else {
        invalidRows.add(parsedRow);
      }
    }

    return ParseResult(
      validRows: validRows,
      invalidRows: invalidRows,
      globalErrors: globalErrors,
      categoriesToCreate: categoriesToCreate.toList(),
      accountsToCreate: accountsToCreate.toList(),
    );
  }

  /// Parse a string value to the appropriate Dart type.
  dynamic _parseValue(String value, FieldType type, String fieldKey) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'null') return null;

    switch (type) {
      case FieldType.string:
        return trimmed;

      case FieldType.double_:
        // Remove currency symbols, commas, and whitespace
        final cleaned = trimmed
            .replaceAll(RegExp(r'[\$\u20AC\u00A3,\s]'), '')
            .replaceAll(RegExp(r'^\(|\)$'), '-'); // Handle (123.45) as negative
        return double.parse(cleaned);

      case FieldType.int_:
        // Handle both integer and code point formats
        if (trimmed.startsWith('0x')) {
          return int.parse(trimmed.substring(2), radix: 16);
        }
        return int.parse(trimmed);

      case FieldType.bool_:
        final lower = trimmed.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';

      case FieldType.dateTime:
        return _parseDateTime(trimmed);

      case FieldType.accountType:
        return _parseAccountType(trimmed);

      case FieldType.categoryType:
        return _parseCategoryType(trimmed);

      case FieldType.transactionType:
        return _parseTransactionType(trimmed);
    }
  }

  /// Parse a date/time string to DateTime.
  DateTime _parseDateTime(String value) {
    // Try ISO 8601 first
    try {
      return DateTime.parse(value);
    } catch (_) {}

    // Try milliseconds since epoch
    final asInt = int.tryParse(value);
    if (asInt != null) {
      // Determine if it's seconds or milliseconds
      if (asInt > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
      }
    }

    // Try common date formats
    final formats = [
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'MM-dd-yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'yyyy/MM/dd',
      'MMM dd, yyyy',
      'MMMM dd, yyyy',
      'dd MMM yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(value);
      } catch (_) {}
    }

    throw FormatException('Could not parse date: $value');
  }

  /// Parse account type from string.
  AccountType _parseAccountType(String value) {
    final lower = value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

    for (final type in AccountType.values) {
      if (type.name.toLowerCase() == lower) return type;
      if (type.displayName.toLowerCase().replaceAll(' ', '') == lower) return type;
    }

    // Common aliases
    if (lower == 'checking' || lower == 'chequing') return AccountType.bank;
    if (lower == 'credit' || lower == 'cc') return AccountType.creditCard;
    if (lower == 'saving') return AccountType.savings;
    if (lower == 'invest' || lower == 'brokerage') return AccountType.investment;

    throw FormatException('Unknown account type: $value');
  }

  /// Parse category type from string.
  CategoryType _parseCategoryType(String value) {
    final lower = value.toLowerCase();
    if (lower == 'income' || lower == 'in' || lower == 'credit') {
      return CategoryType.income;
    }
    if (lower == 'expense' || lower == 'out' || lower == 'debit') {
      return CategoryType.expense;
    }
    throw FormatException('Unknown category type: $value');
  }

  /// Parse transaction type from string.
  TransactionType _parseTransactionType(String value) {
    final lower = value.toLowerCase();
    if (lower == 'income' || lower == 'in' || lower == 'credit' || lower == 'deposit') {
      return TransactionType.income;
    }
    if (lower == 'expense' || lower == 'out' || lower == 'debit' || lower == 'withdrawal') {
      return TransactionType.expense;
    }
    throw FormatException('Unknown transaction type: $value');
  }

  /// Resolve a foreign key value to an entity ID.
  String? _resolveForeignKey(
    String value,
    String entityType,
    ForeignKeyMatchStrategy strategy,
    Map<String, Category> categoriesById,
    Map<String, Category> categoriesByName,
    Map<String, Account> accountsById,
    Map<String, Account> accountsByName,
    String? defaultCategoryId,
    String? defaultAccountId,
  ) {
    switch (strategy) {
      case ForeignKeyMatchStrategy.byId:
        // Value should be an ID, verify it exists
        if (entityType == 'category') {
          return categoriesById.containsKey(value) ? value : null;
        } else {
          return accountsById.containsKey(value) ? value : null;
        }

      case ForeignKeyMatchStrategy.byName:
        // Value is a name, look up by name
        final normalizedValue = value.toLowerCase().trim();
        if (entityType == 'category') {
          return categoriesByName[normalizedValue]?.id;
        } else {
          return accountsByName[normalizedValue]?.id;
        }

      case ForeignKeyMatchStrategy.useDefault:
        // Return the default entity ID
        if (entityType == 'category') {
          return defaultCategoryId;
        } else {
          return defaultAccountId;
        }

      case ForeignKeyMatchStrategy.createIfMissing:
        // Will be handled in import step
        return null;
    }
  }

  /// Import parsed data into the database.
  Future<FlexibleImportResult> importData(
    ImportEntityType entityType,
    List<ParsedImportRow> rows,
    List<String> categoriesToCreate,
    List<String> accountsToCreate,
    Map<String, Category> categoriesByName,
    Map<String, Account> accountsByName,
  ) async {
    int imported = 0;
    int failed = 0;
    int categoriesCreated = 0;
    int accountsCreated = 0;
    final errors = <String>[];

    // Create missing categories first
    final newCategories = <String, String>{}; // name -> id
    for (final name in categoriesToCreate) {
      try {
        final id = _uuid.v4();
        final category = Category(
          id: id,
          name: name,
          icon: LucideIcons.folder,
          colorIndex: 0,
          type: CategoryType.expense,
          isCustom: true,
          sortOrder: 0,
        );
        await categoryRepository.createCategory(category);
        newCategories[name.toLowerCase()] = id;
        categoriesCreated++;
      } catch (e) {
        errors.add('Failed to create category "$name": $e');
      }
    }

    // Create missing accounts
    final newAccounts = <String, String>{}; // name -> id
    for (final name in accountsToCreate) {
      try {
        final id = _uuid.v4();
        final account = Account(
          id: id,
          name: name,
          type: AccountType.bank,
          balance: 0,
          initialBalance: 0,
          createdAt: DateTime.now(),
        );
        await accountRepository.createAccount(account);
        newAccounts[name.toLowerCase()] = id;
        accountsCreated++;
      } catch (e) {
        errors.add('Failed to create account "$name": $e');
      }
    }

    // Import entities
    for (final row in rows) {
      try {
        switch (entityType) {
          case ImportEntityType.account:
            await _importAccount(row.parsedValues);
            break;
          case ImportEntityType.category:
            await _importCategory(row.parsedValues, newCategories, categoriesByName);
            break;
          case ImportEntityType.transaction:
            await _importTransaction(
              row.parsedValues,
              newCategories,
              newAccounts,
              categoriesByName,
              accountsByName,
            );
            break;
        }
        imported++;
      } catch (e) {
        failed++;
        errors.add('Row ${row.rowIndex}: $e');
      }
    }

    return FlexibleImportResult(
      imported: imported,
      skipped: 0,
      failed: failed,
      categoriesCreated: categoriesCreated,
      accountsCreated: accountsCreated,
      errors: errors,
    );
  }

  Future<void> _importAccount(Map<String, dynamic> values) async {
    final account = Account(
      id: values['id'] as String,
      name: values['name'] as String,
      type: values['type'] as AccountType? ?? AccountType.bank,
      balance: (values['balance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (values['initialBalance'] as num?)?.toDouble() ?? 0.0,
      customColor: values['customColor'] != null
          ? Color(values['customColor'] as int)
          : null,
      customIcon: values['customIcon'] != null
          ? IconData(values['customIcon'] as int, fontFamily: 'MaterialIcons')
          : null,
      createdAt: values['createdAt'] as DateTime? ?? DateTime.now(),
    );
    await accountRepository.upsertAccount(account);
  }

  Future<void> _importCategory(
    Map<String, dynamic> values,
    Map<String, String> newCategories,
    Map<String, Category> categoriesByName,
  ) async {
    String? parentId = values['parentId'] as String?;

    // Resolve parent ID if it was marked for creation
    if (parentId != null && parentId.startsWith('CREATE:')) {
      final parentName = parentId.substring(7).toLowerCase();
      parentId = newCategories[parentName] ?? categoriesByName[parentName]?.id;
    }

    final category = Category(
      id: values['id'] as String,
      name: values['name'] as String,
      icon: values['icon'] != null
          ? IconData(values['icon'] as int, fontFamily: 'lucide', fontPackage: 'lucide_icons')
          : LucideIcons.folder,
      colorIndex: values['colorIndex'] as int? ?? 0,
      type: values['type'] as CategoryType? ?? CategoryType.expense,
      isCustom: values['isCustom'] as bool? ?? true,
      parentId: parentId,
      sortOrder: values['sortOrder'] as int? ?? 0,
    );
    await categoryRepository.upsertCategory(category);
  }

  Future<void> _importTransaction(
    Map<String, dynamic> values,
    Map<String, String> newCategories,
    Map<String, String> newAccounts,
    Map<String, Category> categoriesByName,
    Map<String, Account> accountsByName,
  ) async {
    String categoryId = values['categoryId'] as String;
    String accountId = values['accountId'] as String;

    // Resolve IDs if they were marked for creation
    if (categoryId.startsWith('CREATE:')) {
      final name = categoryId.substring(7).toLowerCase();
      categoryId = newCategories[name] ?? categoriesByName[name]?.id ?? categoryId;
    }
    if (accountId.startsWith('CREATE:')) {
      final name = accountId.substring(7).toLowerCase();
      accountId = newAccounts[name] ?? accountsByName[name]?.id ?? accountId;
    }

    final transaction = Transaction(
      id: values['id'] as String,
      amount: (values['amount'] as num).toDouble(),
      type: values['type'] as TransactionType? ?? TransactionType.expense,
      categoryId: categoryId,
      accountId: accountId,
      date: values['date'] as DateTime,
      note: values['note'] as String?,
      createdAt: values['createdAt'] as DateTime? ?? DateTime.now(),
    );
    await transactionRepository.upsertTransaction(transaction);
  }
}
