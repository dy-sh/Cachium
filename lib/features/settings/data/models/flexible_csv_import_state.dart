import '../../../accounts/data/models/account.dart';
import '../../../categories/data/models/category.dart';
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

  /// Default entities for FK "useDefault" strategy.
  final String? defaultCategoryId;
  final String? defaultAccountId;

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
    this.defaultCategoryId,
    this.defaultAccountId,
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
    String? defaultCategoryId,
    bool clearDefaultCategoryId = false,
    String? defaultAccountId,
    bool clearDefaultAccountId = false,
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
      defaultCategoryId: clearDefaultCategoryId
          ? null
          : (defaultCategoryId ?? this.defaultCategoryId),
      defaultAccountId: clearDefaultAccountId
          ? null
          : (defaultAccountId ?? this.defaultAccountId),
    );
  }

  /// Check if the current configuration is valid for proceeding.
  bool get canProceedToPreview {
    if (config == null) return false;

    final fields = ImportFieldDefinitions.getFieldsForType(entityType!);
    final mappings = config!.fieldMappings;

    // Check all required fields are mapped or have a valid strategy
    for (final field in fields) {
      if (!field.isRequired) continue;

      final mapping = mappings[field.key];
      if (mapping == null) return false;

      // If not mapped, must have a valid strategy
      if (mapping.csvColumn == null) {
        if (field.isId && mapping.missingStrategy != MissingFieldStrategy.generateId) {
          return false;
        }
        if (!field.isId && field.defaultValue == null && mapping.missingStrategy != MissingFieldStrategy.skip) {
          return false;
        }
      }

      // FK fields need a strategy
      if (field.isForeignKey && mapping.csvColumn != null && mapping.fkStrategy == null) {
        return false;
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
}
