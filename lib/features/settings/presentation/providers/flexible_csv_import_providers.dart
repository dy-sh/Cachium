import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/services/flexible_csv_import_service.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/field_mapping_options.dart';
import '../../data/models/flexible_csv_import_config.dart';
import '../../data/models/flexible_csv_import_state.dart';
import '../../data/models/import_preset.dart';
import 'database_management_providers.dart';

/// Provider for the flexible CSV import service.
final flexibleCsvImportServiceProvider = Provider<FlexibleCsvImportService>((ref) {
  return FlexibleCsvImportService(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
});

/// Provider for field definitions based on entity type.
final fieldDefinitionsProvider = Provider.family<List<AppFieldDefinition>, ImportEntityType>((ref, type) {
  return ImportFieldDefinitions.getFieldsForType(type);
});

/// Provider for available presets based on entity type.
final presetsForTypeProvider = Provider.family<List<ImportPreset>, ImportEntityType>((ref, type) {
  return BuiltInPresets.getPresetsForType(type);
});

/// Main state provider for flexible CSV import wizard.
final flexibleCsvImportProvider =
    NotifierProvider.autoDispose<FlexibleCsvImportNotifier, FlexibleCsvImportState>(
  FlexibleCsvImportNotifier.new,
);

/// Notifier for managing flexible CSV import state.
class FlexibleCsvImportNotifier extends AutoDisposeNotifier<FlexibleCsvImportState> {
  @override
  FlexibleCsvImportState build() {
    return const FlexibleCsvImportState();
  }

  FlexibleCsvImportService get _service => ref.read(flexibleCsvImportServiceProvider);

  /// Select the entity type to import.
  void selectEntityType(ImportEntityType type) {
    state = state.copyWith(
      entityType: type,
      step: ImportWizardStep.selectFile,
      clearError: true,
    );
  }

  /// Go back to entity type selection.
  void goBackToTypeSelection() {
    state = const FlexibleCsvImportState();
  }

  /// Pick and load a CSV file.
  Future<bool> loadCsvFile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final path = result.files.first.path;
      if (path == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not access selected file',
        );
        return false;
      }

      final parsed = await _service.loadCsvFile(path);
      if (parsed == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not parse CSV file',
        );
        return false;
      }

      // Load existing entities for FK resolution
      await _loadExistingEntities();

      // Try to detect a matching preset
      final detectedPreset = BuiltInPresets.detectPreset(
        state.entityType!,
        parsed.headers,
      );

      // Use preset mappings if detected, otherwise auto-detect
      Map<String, FieldMapping> mappings;
      ImportPreset? appliedPreset;

      if (detectedPreset != null) {
        mappings = detectedPreset.applyToHeaders(parsed.headers);
        appliedPreset = detectedPreset;
      } else {
        mappings = _service.autoDetectMappings(
          state.entityType!,
          parsed.headers,
        );
      }

      final config = FlexibleCsvImportConfig(
        entityType: state.entityType!,
        filePath: path,
        csvHeaders: parsed.headers,
        csvRows: parsed.rows,
        fieldMappings: mappings,
        presetName: appliedPreset?.name,
      );

      // For transactions, populate FK configs from mappings
      ForeignKeyConfig categoryConfig = const ForeignKeyConfig();
      ForeignKeyConfig accountConfig = const ForeignKeyConfig();

      if (state.entityType == ImportEntityType.transaction) {
        final categoryIdMapping = mappings['categoryId'];
        final categoryNameMapping = mappings['categoryName'];
        if (categoryIdMapping?.csvColumn != null ||
            categoryNameMapping?.csvColumn != null) {
          categoryConfig = ForeignKeyConfig(
            mode: ForeignKeyResolutionMode.mapFromCsv,
            idColumn: categoryIdMapping?.csvColumn,
            nameColumn: categoryNameMapping?.csvColumn,
          );
        }

        final accountIdMapping = mappings['accountId'];
        final accountNameMapping = mappings['accountName'];
        if (accountIdMapping?.csvColumn != null ||
            accountNameMapping?.csvColumn != null) {
          accountConfig = ForeignKeyConfig(
            mode: ForeignKeyResolutionMode.mapFromCsv,
            idColumn: accountIdMapping?.csvColumn,
            nameColumn: accountNameMapping?.csvColumn,
          );
        }
      }

      state = state.copyWith(
        config: config,
        step: ImportWizardStep.mapColumns,
        isLoading: false,
        categoryConfig: categoryConfig,
        accountConfig: accountConfig,
        appliedPreset: appliedPreset,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load file: $e',
      );
      return false;
    }
  }

  /// Load existing categories and accounts for FK resolution.
  Future<void> _loadExistingEntities() async {
    try {
      final categories = await ref.read(categoriesProvider.future);
      final accounts = await ref.read(accountsProvider.future);

      final categoriesByName = <String, Category>{};
      final categoriesById = <String, Category>{};
      for (final cat in categories) {
        categoriesByName[cat.name.toLowerCase()] = cat;
        categoriesById[cat.id] = cat;
      }

      final accountsByName = <String, Account>{};
      final accountsById = <String, Account>{};
      for (final acc in accounts) {
        accountsByName[acc.name.toLowerCase()] = acc;
        accountsById[acc.id] = acc;
      }

      state = state.copyWith(
        existingCategoriesByName: categoriesByName,
        existingCategoriesById: categoriesById,
        existingAccountsByName: accountsByName,
        existingAccountsById: accountsById,
      );
    } catch (_) {
      // Ignore errors, FK resolution will handle missing entities
    }
  }

  /// Apply a preset to the current config.
  void applyPreset(ImportPreset preset) {
    if (state.config == null) return;

    final newMappings = preset.applyToHeaders(state.config!.csvHeaders);
    final csvHeaders = state.config!.csvHeaders;

    // Also apply FK mappings to the FK configs for transactions
    ForeignKeyConfig newCategoryConfig = state.categoryConfig;
    ForeignKeyConfig newAccountConfig = state.accountConfig;

    if (preset.entityType == ImportEntityType.transaction) {
      // Check if preset has category mappings
      final categoryIdCol = preset.columnMappings['categoryId'];
      final categoryNameCol = preset.columnMappings['categoryName'];
      if (categoryIdCol != null || categoryNameCol != null) {
        String? matchedIdCol;
        String? matchedNameCol;

        for (final header in csvHeaders) {
          final normalized = header.toLowerCase().replaceAll(RegExp(r'[_\s]'), '');
          if (categoryIdCol != null &&
              normalized == categoryIdCol.toLowerCase().replaceAll(RegExp(r'[_\s]'), '')) {
            matchedIdCol = header;
          }
          if (categoryNameCol != null &&
              normalized == categoryNameCol.toLowerCase().replaceAll(RegExp(r'[_\s]'), '')) {
            matchedNameCol = header;
          }
        }

        if (matchedIdCol != null || matchedNameCol != null) {
          newCategoryConfig = ForeignKeyConfig(
            mode: ForeignKeyResolutionMode.mapFromCsv,
            idColumn: matchedIdCol,
            nameColumn: matchedNameCol,
          );
        }
      }

      // Check if preset has account mappings
      final accountIdCol = preset.columnMappings['accountId'];
      final accountNameCol = preset.columnMappings['accountName'];
      if (accountIdCol != null || accountNameCol != null) {
        String? matchedIdCol;
        String? matchedNameCol;

        for (final header in csvHeaders) {
          final normalized = header.toLowerCase().replaceAll(RegExp(r'[_\s]'), '');
          if (accountIdCol != null &&
              normalized == accountIdCol.toLowerCase().replaceAll(RegExp(r'[_\s]'), '')) {
            matchedIdCol = header;
          }
          if (accountNameCol != null &&
              normalized == accountNameCol.toLowerCase().replaceAll(RegExp(r'[_\s]'), '')) {
            matchedNameCol = header;
          }
        }

        if (matchedIdCol != null || matchedNameCol != null) {
          newAccountConfig = ForeignKeyConfig(
            mode: ForeignKeyResolutionMode.mapFromCsv,
            idColumn: matchedIdCol,
            nameColumn: matchedNameCol,
          );
        }
      }
    }

    state = state.copyWith(
      config: state.config!.copyWith(
        fieldMappings: newMappings,
        presetName: preset.name,
      ),
      appliedPreset: preset,
      categoryConfig: newCategoryConfig,
      accountConfig: newAccountConfig,
    );
  }

  /// Update a field mapping.
  void updateFieldMapping({
    required String fieldKey,
    String? csvColumn,
    bool clearCsvColumn = false,
    MissingFieldStrategy? missingStrategy,
    dynamic defaultValue,
  }) {
    if (state.config == null) return;

    final currentMapping = state.config!.fieldMappings[fieldKey];
    if (currentMapping == null) return;

    final newMapping = currentMapping.copyWith(
      csvColumn: csvColumn,
      clearCsvColumn: clearCsvColumn,
      missingStrategy: missingStrategy,
      defaultValue: defaultValue,
    );

    final newMappings = Map<String, FieldMapping>.from(state.config!.fieldMappings);
    newMappings[fieldKey] = newMapping;

    state = state.copyWith(
      config: state.config!.copyWith(fieldMappings: newMappings),
      clearAppliedPreset: true, // Clear preset indicator when manually changed
    );
  }

  /// Select a target field in the two-panel mapping view.
  void selectField(String? fieldKey) {
    state = state.copyWith(
      selectedFieldKey: fieldKey,
      clearSelectedFieldKey: fieldKey == null,
    );
  }

  /// Connect a CSV column to the currently selected target field.
  /// If the field was already mapped to a different column, that mapping is cleared.
  /// If the CSV column was already mapped to a different field, that mapping is cleared.
  void connectToCsvColumn(String csvColumn) {
    if (state.config == null || state.selectedFieldKey == null) return;

    final fieldKey = state.selectedFieldKey!;
    final newMappings = Map<String, FieldMapping>.from(state.config!.fieldMappings);

    // Clear any existing mapping that uses this CSV column
    for (final entry in newMappings.entries) {
      if (entry.value.csvColumn == csvColumn && entry.key != fieldKey) {
        newMappings[entry.key] = entry.value.copyWith(clearCsvColumn: true);
      }
    }

    // Set the new mapping
    final currentMapping = newMappings[fieldKey];
    if (currentMapping != null) {
      newMappings[fieldKey] = currentMapping.copyWith(csvColumn: csvColumn);
    }

    state = state.copyWith(
      config: state.config!.copyWith(fieldMappings: newMappings),
      clearSelectedFieldKey: true,
      clearAppliedPreset: true,
    );
  }

  /// Clear the mapping for a CSV column.
  void clearConnectionForCsvColumn(String csvColumn) {
    if (state.config == null) return;

    final newMappings = Map<String, FieldMapping>.from(state.config!.fieldMappings);

    for (final entry in newMappings.entries) {
      if (entry.value.csvColumn == csvColumn) {
        newMappings[entry.key] = entry.value.copyWith(clearCsvColumn: true);
        break;
      }
    }

    state = state.copyWith(
      config: state.config!.copyWith(fieldMappings: newMappings),
      clearSelectedFieldKey: true,
      clearAppliedPreset: true,
    );
  }

  /// Clear the mapping for a field.
  void clearConnectionForField(String fieldKey) {
    if (state.config == null) return;

    final currentMapping = state.config!.fieldMappings[fieldKey];
    if (currentMapping == null) return;

    final newMappings = Map<String, FieldMapping>.from(state.config!.fieldMappings);
    newMappings[fieldKey] = currentMapping.copyWith(clearCsvColumn: true);

    state = state.copyWith(
      config: state.config!.copyWith(fieldMappings: newMappings),
      clearSelectedFieldKey: true,
      clearAppliedPreset: true,
    );
  }

  /// Toggle the expanded state of a foreign key ('category' or 'account').
  void toggleExpandedForeignKey(String? foreignKey) {
    if (state.expandedForeignKey == foreignKey) {
      state = state.copyWith(clearExpandedForeignKey: true);
    } else {
      state = state.copyWith(expandedForeignKey: foreignKey);
    }
  }

  /// Update the category FK config.
  void updateCategoryConfig(ForeignKeyConfig config) {
    state = state.copyWith(categoryConfig: config);
  }

  /// Update the account FK config.
  void updateAccountConfig(ForeignKeyConfig config) {
    state = state.copyWith(accountConfig: config);
  }

  /// Set the resolution mode for a foreign key.
  void setForeignKeyMode(String foreignKey, ForeignKeyResolutionMode mode) {
    if (foreignKey == 'category') {
      state = state.copyWith(
        categoryConfig: state.categoryConfig.copyWith(
          mode: mode,
          clearSelectedEntityId: mode != ForeignKeyResolutionMode.useSameForAll,
        ),
        clearAppliedPreset: true,
      );
    } else if (foreignKey == 'account') {
      state = state.copyWith(
        accountConfig: state.accountConfig.copyWith(
          mode: mode,
          clearSelectedEntityId: mode != ForeignKeyResolutionMode.useSameForAll,
        ),
        clearAppliedPreset: true,
      );
    }
  }

  /// Set the selected entity for "use same for all" mode.
  void setForeignKeyEntity(String foreignKey, String? entityId) {
    if (foreignKey == 'category') {
      state = state.copyWith(
        categoryConfig: state.categoryConfig.copyWith(
          selectedEntityId: entityId,
          clearSelectedEntityId: entityId == null,
        ),
        clearAppliedPreset: true,
      );
    } else if (foreignKey == 'account') {
      state = state.copyWith(
        accountConfig: state.accountConfig.copyWith(
          selectedEntityId: entityId,
          clearSelectedEntityId: entityId == null,
        ),
        clearAppliedPreset: true,
      );
    }
  }

  /// Select a FK sub-field for mapping.
  void selectForeignKeyField(String foreignKey, String subField) {
    // Use a special key format: "fk:category:name" or "fk:account:id"
    selectField('fk:$foreignKey:$subField');
  }

  /// Connect a CSV column to the selected FK sub-field.
  void connectCsvColumnToForeignKey(String csvColumn) {
    if (state.selectedFieldKey == null ||
        !state.selectedFieldKey!.startsWith('fk:')) return;

    final parts = state.selectedFieldKey!.split(':');
    if (parts.length != 3) return;

    final foreignKey = parts[1];
    final subField = parts[2];

    // Clear this column from regular field mappings
    if (state.config != null) {
      final newMappings = Map<String, FieldMapping>.from(state.config!.fieldMappings);
      for (final entry in newMappings.entries) {
        if (entry.value.csvColumn == csvColumn) {
          newMappings[entry.key] = entry.value.copyWith(clearCsvColumn: true);
        }
      }
      state = state.copyWith(
        config: state.config!.copyWith(fieldMappings: newMappings),
      );
    }

    if (foreignKey == 'category') {
      if (subField == 'name') {
        state = state.copyWith(
          categoryConfig: state.categoryConfig.copyWith(nameColumn: csvColumn),
          clearSelectedFieldKey: true,
          clearAppliedPreset: true,
        );
      } else if (subField == 'id') {
        state = state.copyWith(
          categoryConfig: state.categoryConfig.copyWith(idColumn: csvColumn),
          clearSelectedFieldKey: true,
          clearAppliedPreset: true,
        );
      }
    } else if (foreignKey == 'account') {
      if (subField == 'name') {
        state = state.copyWith(
          accountConfig: state.accountConfig.copyWith(nameColumn: csvColumn),
          clearSelectedFieldKey: true,
          clearAppliedPreset: true,
        );
      } else if (subField == 'id') {
        state = state.copyWith(
          accountConfig: state.accountConfig.copyWith(idColumn: csvColumn),
          clearSelectedFieldKey: true,
          clearAppliedPreset: true,
        );
      }
    }
  }

  /// Clear a FK sub-field mapping.
  void clearForeignKeyField(String foreignKey, String subField) {
    if (foreignKey == 'category') {
      if (subField == 'name') {
        state = state.copyWith(
          categoryConfig: state.categoryConfig.copyWith(clearNameColumn: true),
          clearAppliedPreset: true,
        );
      } else if (subField == 'id') {
        state = state.copyWith(
          categoryConfig: state.categoryConfig.copyWith(clearIdColumn: true),
          clearAppliedPreset: true,
        );
      }
    } else if (foreignKey == 'account') {
      if (subField == 'name') {
        state = state.copyWith(
          accountConfig: state.accountConfig.copyWith(clearNameColumn: true),
          clearAppliedPreset: true,
        );
      } else if (subField == 'id') {
        state = state.copyWith(
          accountConfig: state.accountConfig.copyWith(clearIdColumn: true),
          clearAppliedPreset: true,
        );
      }
    }
  }

  /// Generate preview of parsed data.
  Future<bool> generatePreview() async {
    if (state.config == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Build config with FK column mappings
      final configWithFkMappings = _buildConfigWithFkMappings();

      // Determine if using "same for all" mode
      final useSameCategoryForAll =
          state.categoryConfig.mode == ForeignKeyResolutionMode.useSameForAll;
      final useSameAccountForAll =
          state.accountConfig.mode == ForeignKeyResolutionMode.useSameForAll;

      final parseResult = await _service.parseAndValidate(
        configWithFkMappings,
        state.existingCategoriesById,
        state.existingCategoriesByName,
        state.existingAccountsById,
        state.existingAccountsByName,
        useSameCategoryForAll,
        useSameAccountForAll,
        state.categoryConfig.selectedEntityId,
        state.accountConfig.selectedEntityId,
      );

      state = state.copyWith(
        parseResult: parseResult,
        step: ImportWizardStep.preview,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to parse data: $e',
      );
      return false;
    }
  }

  /// Build config with FK column mappings from the consolidated configs.
  FlexibleCsvImportConfig _buildConfigWithFkMappings() {
    if (state.config == null) return state.config!;

    final newMappings = Map<String, FieldMapping>.from(state.config!.fieldMappings);

    // Apply category config
    if (state.categoryConfig.mode == ForeignKeyResolutionMode.mapFromCsv) {
      if (state.categoryConfig.nameColumn != null) {
        newMappings['categoryName'] = FieldMapping(
          fieldKey: 'categoryName',
          csvColumn: state.categoryConfig.nameColumn,
        );
      }
      if (state.categoryConfig.idColumn != null) {
        newMappings['categoryId'] = FieldMapping(
          fieldKey: 'categoryId',
          csvColumn: state.categoryConfig.idColumn,
        );
      }
    }

    // Apply account config
    if (state.accountConfig.mode == ForeignKeyResolutionMode.mapFromCsv) {
      if (state.accountConfig.nameColumn != null) {
        newMappings['accountName'] = FieldMapping(
          fieldKey: 'accountName',
          csvColumn: state.accountConfig.nameColumn,
        );
      }
      if (state.accountConfig.idColumn != null) {
        newMappings['accountId'] = FieldMapping(
          fieldKey: 'accountId',
          csvColumn: state.accountConfig.idColumn,
        );
      }
    }

    return state.config!.copyWith(fieldMappings: newMappings);
  }

  /// Go back to column mapping from preview.
  void goBackToMapping() {
    state = state.copyWith(
      step: ImportWizardStep.mapColumns,
      clearParseResult: true,
    );
  }

  /// Execute the import.
  Future<bool> executeImport() async {
    if (state.config == null || state.parseResult == null) return false;

    state = state.copyWith(
      step: ImportWizardStep.importing,
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await _service.importData(
        state.config!.entityType,
        state.parseResult!.validRows,
        state.parseResult!.categoriesToCreate,
        state.parseResult!.accountsToCreate,
        state.existingCategoriesByName,
        state.existingAccountsByName,
      );

      // Invalidate providers to refresh data
      ref.invalidate(categoriesProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);

      // Recalculate account balances if transactions were imported
      if (state.config!.entityType == ImportEntityType.transaction && result.imported > 0) {
        await _recalculateAccountBalances();
      }

      state = state.copyWith(
        importResult: result,
        step: ImportWizardStep.complete,
        isLoading: false,
      );

      return !result.hasErrors;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Import failed: $e',
        step: ImportWizardStep.preview,
      );
      return false;
    }
  }

  /// Recalculate account balances based on transaction history.
  Future<void> _recalculateAccountBalances() async {
    final recalculator = ref.read(recalculateBalancesProvider.notifier);
    await recalculator.calculatePreview();
    await recalculator.applyChanges();
  }

  /// Reset the wizard to start over.
  void reset() {
    state = const FlexibleCsvImportState();
  }
}

/// Provider for checking if all required fields are mapped.
final canProceedToPreviewProvider = Provider<bool>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.canProceedToPreview;
});

/// Provider for unmapped CSV columns.
final unmappedCsvColumnsProvider = Provider<List<String>>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.unmappedCsvColumns;
});

/// Provider for the currently selected target field key.
final selectedFieldKeyProvider = Provider<String?>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.selectedFieldKey;
});

/// Provider for connection badges.
final connectionBadgesProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.connectionBadges;
});

/// Provider for the currently expanded foreign key ('category' or 'account').
final expandedForeignKeyProvider = Provider<String?>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.expandedForeignKey;
});

/// Provider for category FK config.
final categoryConfigProvider = Provider<ForeignKeyConfig>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.categoryConfig;
});

/// Provider for account FK config.
final accountConfigProvider = Provider<ForeignKeyConfig>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.accountConfig;
});

/// Provider for mapping progress (mapped count / total required).
final mappingProgressProvider = Provider<(int mapped, int total)>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return (state.mappedFieldCount, state.totalFieldCount);
});

/// Provider for the current CSV file name.
final currentCsvFileNameProvider = Provider<String?>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  if (state.config == null) return null;
  return state.config!.filePath.split('/').last;
});
