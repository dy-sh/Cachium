import '../../../accounts/data/models/account.dart';
import '../../../categories/data/models/category.dart';
import 'field_mapping_options.dart';
import 'flexible_csv_import_config.dart';
import 'import_preset.dart';

/// Steps in the import wizard.
enum ImportWizardStep {
  selectType,
  selectFile,
  mapColumns,
  preview,
  importing,
  complete,
}

/// A parsed row that's ready for import (or has validation errors).
class ParsedImportRow {
  final int rowIndex;
  final Map<String, dynamic> parsedValues;
  final List<String> errors;
  final List<String> warnings;

  const ParsedImportRow({
    required this.rowIndex,
    required this.parsedValues,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Result of parsing and validating CSV data.
class ParseResult {
  final List<ParsedImportRow> validRows;
  final List<ParsedImportRow> invalidRows;
  final List<String> globalErrors;

  /// Entities that will be created due to "Create if Missing" strategy.
  final List<String> categoriesToCreate;
  final List<String> accountsToCreate;

  const ParseResult({
    required this.validRows,
    required this.invalidRows,
    this.globalErrors = const [],
    this.categoriesToCreate = const [],
    this.accountsToCreate = const [],
  });

  int get totalRows => validRows.length + invalidRows.length;
  int get validCount => validRows.length;
  int get invalidCount => invalidRows.length;
  bool get hasErrors => invalidRows.isNotEmpty || globalErrors.isNotEmpty;
}

/// Result of the import operation.
class FlexibleImportResult {
  final int imported;
  final int skipped;
  final int failed;
  final int categoriesCreated;
  final int accountsCreated;
  final List<String> errors;

  const FlexibleImportResult({
    required this.imported,
    required this.skipped,
    required this.failed,
    this.categoriesCreated = 0,
    this.accountsCreated = 0,
    this.errors = const [],
  });

  int get total => imported + skipped + failed;
  bool get hasErrors => errors.isNotEmpty || failed > 0;
}

/// State for the flexible CSV import wizard.
class FlexibleCsvImportState {
  final ImportWizardStep step;
  final ImportEntityType? entityType;
  final FlexibleCsvImportConfig? config;
  final ImportPreset? appliedPreset;
  final ParseResult? parseResult;
  final FlexibleImportResult? importResult;
  final bool isLoading;
  final String? error;

  /// Existing entities for FK resolution (name -> id lookup).
  final Map<String, Category> existingCategoriesByName;
  final Map<String, Category> existingCategoriesById;
  final Map<String, Account> existingAccountsByName;
  final Map<String, Account> existingAccountsById;

  /// Currently selected target field in the two-panel mapping view.
  final String? selectedFieldKey;

  /// Currently expanded foreign key ('category' or 'account').
  final String? expandedForeignKey;

  /// Foreign key configurations for transactions.
  final ForeignKeyConfig categoryConfig;
  final ForeignKeyConfig accountConfig;

  /// Amount configuration for transactions.
  final AmountConfig amountConfig;

  const FlexibleCsvImportState({
    this.step = ImportWizardStep.selectType,
    this.entityType,
    this.config,
    this.appliedPreset,
    this.parseResult,
    this.importResult,
    this.isLoading = false,
    this.error,
    this.existingCategoriesByName = const {},
    this.existingCategoriesById = const {},
    this.existingAccountsByName = const {},
    this.existingAccountsById = const {},
    this.selectedFieldKey,
    this.expandedForeignKey,
    this.categoryConfig = const ForeignKeyConfig(),
    this.accountConfig = const ForeignKeyConfig(),
    this.amountConfig = const AmountConfig(),
  });

  FlexibleCsvImportState copyWith({
    ImportWizardStep? step,
    ImportEntityType? entityType,
    FlexibleCsvImportConfig? config,
    ImportPreset? appliedPreset,
    bool clearAppliedPreset = false,
    ParseResult? parseResult,
    bool clearParseResult = false,
    FlexibleImportResult? importResult,
    bool clearImportResult = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, Category>? existingCategoriesByName,
    Map<String, Category>? existingCategoriesById,
    Map<String, Account>? existingAccountsByName,
    Map<String, Account>? existingAccountsById,
    String? selectedFieldKey,
    bool clearSelectedFieldKey = false,
    String? expandedForeignKey,
    bool clearExpandedForeignKey = false,
    ForeignKeyConfig? categoryConfig,
    ForeignKeyConfig? accountConfig,
    AmountConfig? amountConfig,
  }) {
    return FlexibleCsvImportState(
      step: step ?? this.step,
      entityType: entityType ?? this.entityType,
      config: config ?? this.config,
      appliedPreset:
          clearAppliedPreset ? null : (appliedPreset ?? this.appliedPreset),
      parseResult:
          clearParseResult ? null : (parseResult ?? this.parseResult),
      importResult:
          clearImportResult ? null : (importResult ?? this.importResult),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      existingCategoriesByName:
          existingCategoriesByName ?? this.existingCategoriesByName,
      existingCategoriesById:
          existingCategoriesById ?? this.existingCategoriesById,
      existingAccountsByName:
          existingAccountsByName ?? this.existingAccountsByName,
      existingAccountsById: existingAccountsById ?? this.existingAccountsById,
      selectedFieldKey: clearSelectedFieldKey
          ? null
          : (selectedFieldKey ?? this.selectedFieldKey),
      expandedForeignKey: clearExpandedForeignKey
          ? null
          : (expandedForeignKey ?? this.expandedForeignKey),
      categoryConfig: categoryConfig ?? this.categoryConfig,
      accountConfig: accountConfig ?? this.accountConfig,
      amountConfig: amountConfig ?? this.amountConfig,
    );
  }

  /// Check if the current configuration is valid for proceeding.
  bool get canProceedToPreview {
    if (config == null) return false;

    final fields = ImportFieldDefinitions.getFieldsForType(entityType!);
    final mappings = config!.fieldMappings;

    // For transactions, check category/account/amount configs are valid
    if (entityType == ImportEntityType.transaction) {
      if (!categoryConfig.isValid) return false;
      if (!accountConfig.isValid) return false;
      if (!amountConfig.isValid) return false;
    }

    // Check other required fields are mapped or have a valid strategy
    for (final field in fields) {
      if (!field.isRequired) continue;
      if (field.isForeignKey) continue; // Handled above for transactions
      // Skip amount and type for transactions - handled by amountConfig
      if (entityType == ImportEntityType.transaction &&
          (field.key == 'amount' || field.key == 'type')) {
        continue;
      }

      final mapping = mappings[field.key];
      if (mapping == null) return false;

      // If not mapped, must have a valid strategy
      if (mapping.csvColumn == null) {
        if (field.isId && mapping.missingStrategy != MissingFieldStrategy.generateId) {
          return false;
        }
        if (!field.isId && field.defaultValue == null) {
          return false;
        }
      }
    }

    return true;
  }

  /// Get the CSV column names that are not yet mapped.
  List<String> get unmappedCsvColumns {
    if (config == null) return [];

    final mappedColumns = config!.fieldMappings.values
        .where((m) => m.csvColumn != null)
        .map((m) => m.csvColumn!)
        .toSet();

    return config!.csvHeaders
        .where((h) => !mappedColumns.contains(h))
        .toList();
  }

  /// Get connection badges for mapped CSV columns and fields.
  /// Returns a map where keys are CSV column names and values are badge numbers (1-indexed).
  Map<String, int> get connectionBadges {
    if (config == null) return {};

    final badges = <String, int>{};
    int badgeNumber = 1;

    // Assign badge numbers in the order columns appear in the CSV headers
    for (final header in config!.csvHeaders) {
      // Check if this column is mapped to any field
      for (final mapping in config!.fieldMappings.values) {
        if (mapping.csvColumn == header) {
          badges[header] = badgeNumber;
          badgeNumber++;
          break;
        }
      }
    }

    return badges;
  }

  /// Get the field key that a CSV column is mapped to.
  String? getFieldKeyForCsvColumn(String csvColumn) {
    if (config == null) return null;

    for (final entry in config!.fieldMappings.entries) {
      if (entry.value.csvColumn == csvColumn) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get the CSV column that a field is mapped to.
  String? getCsvColumnForField(String fieldKey) {
    if (config == null) return null;
    return config!.fieldMappings[fieldKey]?.csvColumn;
  }

  /// Get badge number for a field key.
  int? getBadgeForField(String fieldKey) {
    final csvColumn = getCsvColumnForField(fieldKey);
    if (csvColumn == null) return null;
    return connectionBadges[csvColumn];
  }

  /// Get the count of mapped fields (for progress display).
  /// Counts non-FK fields that are mapped, plus FK/amount configs that are valid.
  int get mappedFieldCount {
    if (config == null || entityType == null) return 0;
    final fields = ImportFieldDefinitions.getFieldsForType(entityType!);

    // For transactions, exclude FK fields AND amount/type fields
    final excludedKeys = entityType == ImportEntityType.transaction
        ? fields
            .where((f) => f.isForeignKey || f.key == 'amount' || f.key == 'type')
            .map((f) => f.key)
            .toSet()
        : fields.where((f) => f.isForeignKey).map((f) => f.key).toSet();

    int count = config!.fieldMappings.entries
        .where((e) => !excludedKeys.contains(e.key) && e.value.csvColumn != null)
        .length;

    // For transactions, add FK and amount configs if valid
    if (entityType == ImportEntityType.transaction) {
      if (categoryConfig.isValid) count++;
      if (accountConfig.isValid) count++;
      if (amountConfig.isValid) count++;
    }

    return count;
  }

  /// Get the total field count (visible items in UI).
  /// For transactions: non-FK fields (excluding amount/type) + 3 consolidated items
  /// (Category, Account, Amount).
  int get totalFieldCount {
    if (entityType == null) return 0;
    final fields = ImportFieldDefinitions.getFieldsForType(entityType!);

    if (entityType == ImportEntityType.transaction) {
      // Exclude FK fields and amount/type (they're handled by consolidated items)
      int count = fields
          .where((f) => !f.isForeignKey && f.key != 'amount' && f.key != 'type')
          .length;
      // Add 3 for consolidated Category, Account, and Amount items
      count += 3;
      return count;
    }

    // For other entity types, just count non-FK fields
    return fields.where((f) => !f.isForeignKey).length;
  }
}
