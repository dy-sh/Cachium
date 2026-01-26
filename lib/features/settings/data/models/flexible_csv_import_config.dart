import '../../../accounts/data/models/account.dart';
import '../../../categories/data/models/category.dart';
import '../../../transactions/data/models/transaction.dart';

/// The type of entity to import from CSV.
enum ImportEntityType {
  account('Accounts'),
  category('Categories'),
  transaction('Transactions');

  final String displayName;
  const ImportEntityType(this.displayName);
}

/// How to handle missing required fields during import.
enum MissingFieldStrategy {
  /// Generate a UUID for ID fields.
  generateId('Generate ID'),

  /// Use a default value (specified in field definition).
  useDefault('Use Default'),

  /// Skip rows with missing required fields.
  skip('Skip Row');

  final String displayName;
  const MissingFieldStrategy(this.displayName);
}

/// Type of data for a field.
enum FieldType {
  string,
  double_,
  int_,
  bool_,
  dateTime,
  accountType,
  categoryType,
  transactionType,
}

/// Metadata about an app field that can be mapped from CSV.
class AppFieldDefinition {
  final String key;
  final String displayName;
  final FieldType type;
  final bool isRequired;
  final bool isId;
  final bool isForeignKey;
  final String? foreignKeyEntity; // 'account' or 'category'
  final dynamic defaultValue;
  final String? description;

  const AppFieldDefinition({
    required this.key,
    required this.displayName,
    required this.type,
    this.isRequired = false,
    this.isId = false,
    this.isForeignKey = false,
    this.foreignKeyEntity,
    this.defaultValue,
    this.description,
  });
}

/// Maps a CSV column to an app field with strategies for handling values.
class FieldMapping {
  /// The app field key this mapping is for.
  final String fieldKey;

  /// The CSV column name (null if not mapped).
  final String? csvColumn;

  /// Strategy for handling missing values.
  final MissingFieldStrategy missingStrategy;

  /// Default value to use (for useDefault strategy).
  final dynamic defaultValue;

  const FieldMapping({
    required this.fieldKey,
    this.csvColumn,
    this.missingStrategy = MissingFieldStrategy.skip,
    this.defaultValue,
  });

  FieldMapping copyWith({
    String? fieldKey,
    String? csvColumn,
    bool clearCsvColumn = false,
    MissingFieldStrategy? missingStrategy,
    dynamic defaultValue,
  }) {
    return FieldMapping(
      fieldKey: fieldKey ?? this.fieldKey,
      csvColumn: clearCsvColumn ? null : (csvColumn ?? this.csvColumn),
      missingStrategy: missingStrategy ?? this.missingStrategy,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }
}

/// Complete configuration for a flexible CSV import.
class FlexibleCsvImportConfig {
  final ImportEntityType entityType;
  final String filePath;
  final List<String> csvHeaders;
  final List<List<dynamic>> csvRows;
  final Map<String, FieldMapping> fieldMappings;
  final String? presetName;

  const FlexibleCsvImportConfig({
    required this.entityType,
    required this.filePath,
    required this.csvHeaders,
    required this.csvRows,
    required this.fieldMappings,
    this.presetName,
  });

  FlexibleCsvImportConfig copyWith({
    ImportEntityType? entityType,
    String? filePath,
    List<String>? csvHeaders,
    List<List<dynamic>>? csvRows,
    Map<String, FieldMapping>? fieldMappings,
    String? presetName,
  }) {
    return FlexibleCsvImportConfig(
      entityType: entityType ?? this.entityType,
      filePath: filePath ?? this.filePath,
      csvHeaders: csvHeaders ?? this.csvHeaders,
      csvRows: csvRows ?? this.csvRows,
      fieldMappings: fieldMappings ?? this.fieldMappings,
      presetName: presetName ?? this.presetName,
    );
  }

  /// Get sample values from CSV for a column (up to 3).
  List<String> getSampleValues(String columnName) {
    final columnIndex = csvHeaders.indexOf(columnName);
    if (columnIndex < 0) return [];

    final samples = <String>[];
    for (int i = 0; i < csvRows.length && samples.length < 3; i++) {
      final row = csvRows[i];
      if (columnIndex < row.length) {
        final value = row[columnIndex]?.toString() ?? '';
        if (value.isNotEmpty && value != 'null') {
          samples.add(value);
        }
      }
    }
    return samples;
  }
}

/// Field definitions for each entity type.
class ImportFieldDefinitions {
  static const List<AppFieldDefinition> accountFields = [
    AppFieldDefinition(
      key: 'id',
      displayName: 'ID',
      type: FieldType.string,
      isRequired: true,
      isId: true,
      description: 'Unique identifier (UUID)',
    ),
    AppFieldDefinition(
      key: 'name',
      displayName: 'Name',
      type: FieldType.string,
      isRequired: true,
      description: 'Account name',
    ),
    AppFieldDefinition(
      key: 'type',
      displayName: 'Type',
      type: FieldType.accountType,
      isRequired: true,
      defaultValue: AccountType.bank,
      description: 'Account type (bank, creditCard, cash, etc.)',
    ),
    AppFieldDefinition(
      key: 'balance',
      displayName: 'Balance',
      type: FieldType.double_,
      isRequired: true,
      defaultValue: 0.0,
      description: 'Current balance',
    ),
    AppFieldDefinition(
      key: 'initialBalance',
      displayName: 'Initial Balance',
      type: FieldType.double_,
      defaultValue: 0.0,
      description: 'Starting balance',
    ),
    AppFieldDefinition(
      key: 'customColor',
      displayName: 'Custom Color',
      type: FieldType.int_,
      description: 'Color value (optional)',
    ),
    AppFieldDefinition(
      key: 'customIcon',
      displayName: 'Custom Icon',
      type: FieldType.int_,
      description: 'Icon code point (optional)',
    ),
    AppFieldDefinition(
      key: 'createdAt',
      displayName: 'Created At',
      type: FieldType.dateTime,
      description: 'Creation timestamp',
    ),
    AppFieldDefinition(
      key: 'lastUpdatedAt',
      displayName: 'Last Updated',
      type: FieldType.dateTime,
      description: 'Last modification timestamp (for sync)',
    ),
  ];

  // Icon code point for folder icon (0xe399 is LucideIcons.folder)
  static const int _defaultIconCodePoint = 0xe399;

  static const List<AppFieldDefinition> categoryFields = [
    AppFieldDefinition(
      key: 'id',
      displayName: 'ID',
      type: FieldType.string,
      isRequired: true,
      isId: true,
      description: 'Unique identifier (UUID)',
    ),
    AppFieldDefinition(
      key: 'name',
      displayName: 'Name',
      type: FieldType.string,
      isRequired: true,
      description: 'Category name',
    ),
    AppFieldDefinition(
      key: 'icon',
      displayName: 'Icon',
      type: FieldType.int_,
      isRequired: true,
      defaultValue: _defaultIconCodePoint,
      description: 'Icon code point',
    ),
    AppFieldDefinition(
      key: 'colorIndex',
      displayName: 'Color Index',
      type: FieldType.int_,
      isRequired: true,
      defaultValue: 0,
      description: 'Color palette index',
    ),
    AppFieldDefinition(
      key: 'type',
      displayName: 'Type',
      type: FieldType.categoryType,
      isRequired: true,
      defaultValue: CategoryType.expense,
      description: 'Category type (income/expense)',
    ),
    AppFieldDefinition(
      key: 'isCustom',
      displayName: 'Is Custom',
      type: FieldType.bool_,
      defaultValue: true,
      description: 'Whether this is a custom category',
    ),
    AppFieldDefinition(
      key: 'parentId',
      displayName: 'Parent Category',
      type: FieldType.string,
      isForeignKey: true,
      foreignKeyEntity: 'category',
      description: 'Parent category ID (for subcategories)',
    ),
    AppFieldDefinition(
      key: 'sortOrder',
      displayName: 'Sort Order',
      type: FieldType.int_,
      defaultValue: 0,
      description: 'Display order',
    ),
    AppFieldDefinition(
      key: 'iconFontFamily',
      displayName: 'Icon Font Family',
      type: FieldType.string,
      defaultValue: 'lucide',
      description: 'Font family for icon (default: lucide)',
    ),
    AppFieldDefinition(
      key: 'iconFontPackage',
      displayName: 'Icon Font Package',
      type: FieldType.string,
      defaultValue: 'lucide_icons',
      description: 'Font package for icon (default: lucide_icons)',
    ),
    AppFieldDefinition(
      key: 'lastUpdatedAt',
      displayName: 'Last Updated',
      type: FieldType.dateTime,
      description: 'Last modification timestamp (for sync)',
    ),
  ];

  static const List<AppFieldDefinition> transactionFields = [
    AppFieldDefinition(
      key: 'id',
      displayName: 'ID',
      type: FieldType.string,
      isId: true,
      description: 'Unique identifier (auto-generated if not mapped)',
    ),
    AppFieldDefinition(
      key: 'amount',
      displayName: 'Amount',
      type: FieldType.double_,
      isRequired: true,
      description: 'Transaction amount (positive number)',
    ),
    AppFieldDefinition(
      key: 'type',
      displayName: 'Type',
      type: FieldType.transactionType,
      isRequired: true,
      defaultValue: TransactionType.expense,
      description: 'Transaction type (income/expense)',
    ),
    AppFieldDefinition(
      key: 'categoryId',
      displayName: 'Category ID',
      type: FieldType.string,
      isForeignKey: true,
      foreignKeyEntity: 'category',
      description: 'Category UUID (if you have IDs)',
    ),
    AppFieldDefinition(
      key: 'categoryName',
      displayName: 'Category Name',
      type: FieldType.string,
      isForeignKey: true,
      foreignKeyEntity: 'category',
      description: 'Category name for lookup/creation',
    ),
    AppFieldDefinition(
      key: 'accountId',
      displayName: 'Account ID',
      type: FieldType.string,
      isForeignKey: true,
      foreignKeyEntity: 'account',
      description: 'Account UUID (if you have IDs)',
    ),
    AppFieldDefinition(
      key: 'accountName',
      displayName: 'Account Name',
      type: FieldType.string,
      isForeignKey: true,
      foreignKeyEntity: 'account',
      description: 'Account name for lookup/creation',
    ),
    AppFieldDefinition(
      key: 'date',
      displayName: 'Date',
      type: FieldType.dateTime,
      description: 'Transaction date (uses today if not mapped)',
    ),
    AppFieldDefinition(
      key: 'note',
      displayName: 'Note',
      type: FieldType.string,
      description: 'Optional note/memo',
    ),
    AppFieldDefinition(
      key: 'currency',
      displayName: 'Currency',
      type: FieldType.string,
      defaultValue: 'USD',
      description: 'Currency code (default: USD)',
    ),
    AppFieldDefinition(
      key: 'lastUpdatedAt',
      displayName: 'Last Updated',
      type: FieldType.dateTime,
      description: 'Last modification timestamp (for sync)',
    ),
  ];

  static List<AppFieldDefinition> getFieldsForType(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.account:
        return accountFields;
      case ImportEntityType.category:
        return categoryFields;
      case ImportEntityType.transaction:
        return transactionFields;
    }
  }
}
