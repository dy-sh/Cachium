import 'flexible_csv_import_config.dart';

/// A saved column mapping preset for known CSV formats.
class ImportPreset {
  final String id;
  final String name;
  final String description;
  final ImportEntityType entityType;

  /// Map of app field key -> CSV column name.
  final Map<String, String> columnMappings;

  const ImportPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.entityType,
    required this.columnMappings,
  });

  /// Apply this preset to create field mappings for the given CSV headers.
  Map<String, FieldMapping> applyToHeaders(List<String> csvHeaders) {
    final fields = ImportFieldDefinitions.getFieldsForType(entityType);
    final mappings = <String, FieldMapping>{};

    for (final field in fields) {
      final presetColumn = columnMappings[field.key];
      String? matchedColumn;

      // Try to match preset column to actual CSV header
      if (presetColumn != null) {
        for (final header in csvHeaders) {
          if (_normalizeColumnName(header) ==
              _normalizeColumnName(presetColumn)) {
            matchedColumn = header;
            break;
          }
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

  static String _normalizeColumnName(String name) {
    // Normalize to lowercase, remove underscores and spaces
    return name.toLowerCase().replaceAll(RegExp(r'[_\s]'), '');
  }
}

/// Built-in presets for common formats.
class BuiltInPresets {
  /// Preset for Cachium's own CSV export format (transactions).
  static const cachiumTransactions = ImportPreset(
    id: 'cachium_transactions',
    name: 'Cachium Export',
    description: 'Cachium CSV export format',
    entityType: ImportEntityType.transaction,
    columnMappings: {
      'id': 'id',
      'amount': 'amount',
      'type': 'type',
      'categoryId': 'category_id',
      'categoryName': 'category_name',
      'accountId': 'account_id',
      'accountName': 'account_name',
      'date': 'date_millis',
      'note': 'note',
      'createdAt': 'created_at_millis',
    },
  );

  /// Preset for Cachium's own CSV export format (accounts).
  static const cachiumAccounts = ImportPreset(
    id: 'cachium_accounts',
    name: 'Cachium Export',
    description: 'Cachium CSV export format',
    entityType: ImportEntityType.account,
    columnMappings: {
      'id': 'id',
      'name': 'name',
      'type': 'type',
      'balance': 'balance',
      'initialBalance': 'initial_balance',
      'customColor': 'custom_color_value',
      'customIcon': 'custom_icon_code_point',
      'createdAt': 'created_at_millis',
    },
  );

  /// Preset for Cachium's own CSV export format (categories).
  static const cachiumCategories = ImportPreset(
    id: 'cachium_categories',
    name: 'Cachium Export',
    description: 'Cachium CSV export format',
    entityType: ImportEntityType.category,
    columnMappings: {
      'id': 'id',
      'name': 'name',
      'icon': 'icon_code_point',
      'colorIndex': 'color_index',
      'type': 'type',
      'isCustom': 'is_custom',
      'parentId': 'parent_id',
      'sortOrder': 'sort_order',
    },
  );

  /// Get the built-in preset for an entity type (if available).
  static ImportPreset? getPresetForType(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.account:
        return cachiumAccounts;
      case ImportEntityType.category:
        return cachiumCategories;
      case ImportEntityType.transaction:
        return cachiumTransactions;
    }
  }

  /// Get all available presets for an entity type.
  static List<ImportPreset> getPresetsForType(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.account:
        return [cachiumAccounts];
      case ImportEntityType.category:
        return [cachiumCategories];
      case ImportEntityType.transaction:
        return [cachiumTransactions];
    }
  }
}
