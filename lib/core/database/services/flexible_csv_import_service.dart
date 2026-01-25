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
        return ['category_id', 'cat_id'];
      case 'categoryName':
        return ['category', 'cat', 'category_name', 'cat_name'];
      case 'accountId':
        return ['account_id', 'acc_id'];
      case 'accountName':
        return ['account', 'acc', 'account_name', 'acc_name'];
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
    bool useSameCategoryForAll,
    bool useSameAccountForAll,
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
          if (field.isRequired && !field.isForeignKey) {
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

          parsedValues[field.key] = parsed;
        } catch (e) {
          errors.add('Invalid ${field.displayName}: $rawValue');
        }
      }

      // Handle foreign key resolution for transactions
      if (config.entityType == ImportEntityType.transaction) {
        // Resolve category
        if (useSameCategoryForAll && defaultCategoryId != null) {
          parsedValues['categoryId'] = defaultCategoryId;
        } else {
          final categoryResult = _resolveCategoryFromRow(
            parsedValues,
            categoriesById,
            categoriesByName,
          );
          if (categoryResult.id != null) {
            parsedValues['categoryId'] = categoryResult.id;
          } else if (categoryResult.idToCreate != null) {
            // Create with specific ID (from categoryId field)
            categoriesToCreate.add('ID:${categoryResult.idToCreate}:${categoryResult.nameToCreate}');
            parsedValues['categoryId'] = categoryResult.idToCreate;
          } else if (categoryResult.nameToCreate != null) {
            // Create with generated ID (from categoryName field)
            categoriesToCreate.add('NAME:${categoryResult.nameToCreate}');
            parsedValues['categoryId'] = 'CREATE:${categoryResult.nameToCreate}';
          } else {
            errors.add('No category specified');
          }
        }

        // Resolve account
        if (useSameAccountForAll && defaultAccountId != null) {
          parsedValues['accountId'] = defaultAccountId;
        } else {
          final accountResult = _resolveAccountFromRow(
            parsedValues,
            accountsById,
            accountsByName,
          );
          if (accountResult.id != null) {
            parsedValues['accountId'] = accountResult.id;
          } else if (accountResult.idToCreate != null) {
            // Create with specific ID (from accountId field)
            accountsToCreate.add('ID:${accountResult.idToCreate}:${accountResult.nameToCreate}');
            parsedValues['accountId'] = accountResult.idToCreate;
          } else if (accountResult.nameToCreate != null) {
            // Create with generated ID (from accountName field)
            accountsToCreate.add('NAME:${accountResult.nameToCreate}');
            parsedValues['accountId'] = 'CREATE:${accountResult.nameToCreate}';
          } else {
            errors.add('No account specified');
          }
        }
      }

      // Handle parentId for categories (FK resolution)
      if (config.entityType == ImportEntityType.category && parsedValues['parentId'] != null) {
        final parentValue = parsedValues['parentId'].toString();
        // Try by ID first, then by name
        if (categoriesById.containsKey(parentValue)) {
          // Already an ID
        } else {
          final byName = categoriesByName[parentValue.toLowerCase()];
          if (byName != null) {
            parsedValues['parentId'] = byName.id;
          } else {
            // Will need to create
            categoriesToCreate.add(parentValue);
            parsedValues['parentId'] = 'CREATE:$parentValue';
          }
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

  /// Resolve category from row values (categoryId or categoryName).
  /// Returns: id (existing or to use for creation), idToCreate (if we need to create with specific ID), nameToCreate (name for new entity)
  ({String? id, String? idToCreate, String? nameToCreate}) _resolveCategoryFromRow(
    Map<String, dynamic> values,
    Map<String, Category> categoriesById,
    Map<String, Category> categoriesByName,
  ) {
    // Try categoryId first
    final categoryIdValue = values['categoryId'];
    if (categoryIdValue != null) {
      final id = categoryIdValue.toString();
      if (categoriesById.containsKey(id)) {
        return (id: id, idToCreate: null, nameToCreate: null);
      }
      // ID not found - create with this specific ID (use ID as temp name, will be updated when categories are imported)
      return (id: null, idToCreate: id, nameToCreate: 'Imported ($id)');
    }

    // Try categoryName
    final categoryNameValue = values['categoryName'];
    if (categoryNameValue != null) {
      final name = categoryNameValue.toString();
      final normalized = name.toLowerCase().trim();
      final existing = categoriesByName[normalized];
      if (existing != null) {
        return (id: existing.id, idToCreate: null, nameToCreate: null);
      }
      // Name not found, will create with generated ID
      return (id: null, idToCreate: null, nameToCreate: name);
    }

    return (id: null, idToCreate: null, nameToCreate: null);
  }

  /// Resolve account from row values (accountId or accountName).
  /// Returns: id (existing or to use for creation), idToCreate (if we need to create with specific ID), nameToCreate (name for new entity)
  ({String? id, String? idToCreate, String? nameToCreate}) _resolveAccountFromRow(
    Map<String, dynamic> values,
    Map<String, Account> accountsById,
    Map<String, Account> accountsByName,
  ) {
    // Try accountId first
    final accountIdValue = values['accountId'];
    if (accountIdValue != null) {
      final id = accountIdValue.toString();
      if (accountsById.containsKey(id)) {
        return (id: id, idToCreate: null, nameToCreate: null);
      }
      // ID not found - create with this specific ID (use ID as temp name, will be updated when accounts are imported)
      return (id: null, idToCreate: id, nameToCreate: 'Imported ($id)');
    }

    // Try accountName
    final accountNameValue = values['accountName'];
    if (accountNameValue != null) {
      final name = accountNameValue.toString();
      final normalized = name.toLowerCase().trim();
      final existing = accountsByName[normalized];
      if (existing != null) {
        return (id: existing.id, idToCreate: null, nameToCreate: null);
      }
      // Name not found, will create with generated ID
      return (id: null, idToCreate: null, nameToCreate: name);
    }

    return (id: null, idToCreate: null, nameToCreate: null);
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
    // Format: "ID:uuid:name" (create with specific ID) or "NAME:name" (create with generated ID)
    final newCategories = <String, String>{}; // name -> id
    for (final entry in categoriesToCreate) {
      try {
        String id;
        String name;

        if (entry.startsWith('ID:')) {
          // Create with specific ID: "ID:uuid:name"
          final parts = entry.substring(3).split(':');
          id = parts[0];
          name = parts.length > 1 ? parts.sublist(1).join(':') : id;
        } else if (entry.startsWith('NAME:')) {
          // Create with generated ID: "NAME:name"
          id = _uuid.v4();
          name = entry.substring(5);
        } else {
          // Legacy format: just name
          id = _uuid.v4();
          name = entry;
        }

        final category = Category(
          id: id,
          name: name,
          icon: LucideIcons.folder,
          colorIndex: 0,
          type: CategoryType.expense,
          isCustom: true,
          sortOrder: 0,
        );
        await categoryRepository.upsertCategory(category);
        newCategories[name.toLowerCase()] = id;
        categoriesCreated++;
      } catch (e) {
        errors.add('Failed to create category "$entry": $e');
      }
    }

    // Create missing accounts
    // Format: "ID:uuid:name" (create with specific ID) or "NAME:name" (create with generated ID)
    final newAccounts = <String, String>{}; // name -> id
    for (final entry in accountsToCreate) {
      try {
        String id;
        String name;

        if (entry.startsWith('ID:')) {
          // Create with specific ID: "ID:uuid:name"
          final parts = entry.substring(3).split(':');
          id = parts[0];
          name = parts.length > 1 ? parts.sublist(1).join(':') : id;
        } else if (entry.startsWith('NAME:')) {
          // Create with generated ID: "NAME:name"
          id = _uuid.v4();
          name = entry.substring(5);
        } else {
          // Legacy format: just name
          id = _uuid.v4();
          name = entry;
        }

        final account = Account(
          id: id,
          name: name,
          type: AccountType.bank,
          balance: 0,
          initialBalance: 0,
          createdAt: DateTime.now(),
        );
        await accountRepository.upsertAccount(account);
        newAccounts[name.toLowerCase()] = id;
        accountsCreated++;
      } catch (e) {
        errors.add('Failed to create account "$entry": $e');
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
