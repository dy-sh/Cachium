import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/services/flexible_csv_import_service.dart';
import '../../../../accounts/data/models/account.dart';
import '../../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../data/models/field_mapping_options.dart';
import '../../../data/models/flexible_csv_import_config.dart';
import '../../../data/models/flexible_csv_import_state.dart';
import '../../../data/models/import_preset.dart';
import '../database_management_providers.dart';
import 'csv_import_providers.dart';

class FlexibleCsvImportNotifier extends AutoDisposeNotifier<FlexibleCsvImportState> {
  @override
  FlexibleCsvImportState build() {
    return const FlexibleCsvImportState();
  }

  FlexibleCsvImportService get _service => ref.read(flexibleCsvImportServiceProvider);

  void selectEntityType(ImportEntityType type) {
    state = state.copyWith(
      entityType: type,
      step: ImportWizardStep.selectFile,
      clearError: true,
    );
  }

  void goBackToTypeSelection() {
    state = const FlexibleCsvImportState();
  }

  Future<bool> loadCsvFile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      const csvTypeGroup = XTypeGroup(
        label: 'CSV files',
        extensions: ['csv'],
      );
      final file = await openFile(
        acceptedTypeGroups: const [csvTypeGroup],
      );

      if (file == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final path = file.path;

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

      // For transactions, populate FK and amount configs from mappings
      ForeignKeyConfig categoryConfig = const ForeignKeyConfig();
      ForeignKeyConfig accountConfig = const ForeignKeyConfig();
      AmountConfig amountConfig = const AmountConfig();

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

        // Populate amount config from mappings
        final amountMapping = mappings['amount'];
        final typeMapping = mappings['type'];
        if (amountMapping?.csvColumn != null) {
          amountConfig = AmountConfig(
            mode: AmountResolutionMode.separateAmountAndType,
            amountColumn: amountMapping?.csvColumn,
            typeColumn: typeMapping?.csvColumn,
          );
        }
      }

      state = state.copyWith(
        config: config,
        step: ImportWizardStep.mapColumns,
        isLoading: false,
        categoryConfig: categoryConfig,
        accountConfig: accountConfig,
        amountConfig: amountConfig,
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

  void clearAllMappings() {
    if (state.config == null) return;

    final fields = ImportFieldDefinitions.getFieldsForType(state.config!.entityType);
    final newMappings = <String, FieldMapping>{};

    for (final field in fields) {
      newMappings[field.key] = FieldMapping(
        fieldKey: field.key,
        csvColumn: null,
        missingStrategy: field.isId
            ? MissingFieldStrategy.generateId
            : (field.defaultValue != null
                ? MissingFieldStrategy.useDefault
                : MissingFieldStrategy.skip),
        defaultValue: field.defaultValue,
      );
    }

    // Clear FK configs for transactions
    ForeignKeyConfig clearedCategoryConfig = const ForeignKeyConfig();
    ForeignKeyConfig clearedAccountConfig = const ForeignKeyConfig();
    AmountConfig clearedAmountConfig = const AmountConfig();

    state = state.copyWith(
      config: state.config!.copyWith(
        fieldMappings: newMappings,
        clearPresetName: true,
      ),
      clearAppliedPreset: true,
      categoryConfig: clearedCategoryConfig,
      accountConfig: clearedAccountConfig,
      amountConfig: clearedAmountConfig,
    );
  }

  void applyAutoDetect() {
    if (state.config == null) return;

    final mappings = _service.autoDetectMappings(
      state.config!.entityType,
      state.config!.csvHeaders,
    );

    // For transactions, populate FK and amount configs from auto-detected mappings
    ForeignKeyConfig categoryConfig = const ForeignKeyConfig();
    ForeignKeyConfig accountConfig = const ForeignKeyConfig();
    AmountConfig amountConfig = const AmountConfig();

    if (state.config!.entityType == ImportEntityType.transaction) {
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

      // Populate amount config from mappings
      final amountMapping = mappings['amount'];
      final typeMapping = mappings['type'];
      if (amountMapping?.csvColumn != null) {
        amountConfig = AmountConfig(
          mode: AmountResolutionMode.separateAmountAndType,
          amountColumn: amountMapping?.csvColumn,
          typeColumn: typeMapping?.csvColumn,
        );
      }
    }

    state = state.copyWith(
      config: state.config!.copyWith(
        fieldMappings: mappings,
        clearPresetName: true,
      ),
      clearAppliedPreset: true,
      categoryConfig: categoryConfig,
      accountConfig: accountConfig,
      amountConfig: amountConfig,
    );
  }

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

  void selectField(String? fieldKey) {
    state = state.copyWith(
      selectedFieldKey: fieldKey,
      clearSelectedFieldKey: fieldKey == null,
    );
  }

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

  void toggleExpandedForeignKey(String? foreignKey) {
    if (state.expandedForeignKey == foreignKey) {
      state = state.copyWith(clearExpandedForeignKey: true);
    } else {
      state = state.copyWith(expandedForeignKey: foreignKey);
    }
  }

  void updateCategoryConfig(ForeignKeyConfig config) {
    state = state.copyWith(categoryConfig: config);
  }

  void updateAccountConfig(ForeignKeyConfig config) {
    state = state.copyWith(accountConfig: config);
  }

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

  void selectForeignKeyField(String foreignKey, String subField) {
    // Use a special key format: "fk:category:name" or "fk:account:id"
    selectField('fk:$foreignKey:$subField');
  }

  void connectCsvColumnToForeignKey(String csvColumn) {
    if (state.selectedFieldKey == null ||
        !state.selectedFieldKey!.startsWith('fk:')) {
      return;
    }

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

  void setAmountMode(AmountResolutionMode mode) {
    state = state.copyWith(
      amountConfig: state.amountConfig.copyWith(
        mode: mode,
        // Clear type column when switching to signed amount mode
        clearTypeColumn: mode == AmountResolutionMode.signedAmount,
      ),
      clearAppliedPreset: true,
    );
  }

  void selectAmountField(String subField) {
    // Use a special key format: "amount:amount" or "amount:type"
    selectField('amount:$subField');
  }

  void connectCsvColumnToAmount(String csvColumn) {
    if (state.selectedFieldKey == null ||
        !state.selectedFieldKey!.startsWith('amount:')) {
      return;
    }

    final subField = state.selectedFieldKey!.split(':')[1];

    // Clear this column from regular field mappings and other configs
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

    if (subField == 'amount') {
      state = state.copyWith(
        amountConfig: state.amountConfig.copyWith(amountColumn: csvColumn),
        clearSelectedFieldKey: true,
        clearAppliedPreset: true,
      );
    } else if (subField == 'type') {
      state = state.copyWith(
        amountConfig: state.amountConfig.copyWith(typeColumn: csvColumn),
        clearSelectedFieldKey: true,
        clearAppliedPreset: true,
      );
    }
  }

  void clearAmountField(String subField) {
    if (subField == 'amount') {
      state = state.copyWith(
        amountConfig: state.amountConfig.copyWith(clearAmountColumn: true),
        clearAppliedPreset: true,
      );
    } else if (subField == 'type') {
      state = state.copyWith(
        amountConfig: state.amountConfig.copyWith(clearTypeColumn: true),
        clearAppliedPreset: true,
      );
    }
  }

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
        state.amountConfig,
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

    // Apply amount config
    if (state.amountConfig.amountColumn != null) {
      newMappings['amount'] = FieldMapping(
        fieldKey: 'amount',
        csvColumn: state.amountConfig.amountColumn,
      );
    }
    if (state.amountConfig.mode == AmountResolutionMode.separateAmountAndType &&
        state.amountConfig.typeColumn != null) {
      newMappings['type'] = FieldMapping(
        fieldKey: 'type',
        csvColumn: state.amountConfig.typeColumn,
      );
    }

    return state.config!.copyWith(fieldMappings: newMappings);
  }

  void goBackToMapping() {
    state = state.copyWith(
      step: ImportWizardStep.mapColumns,
      clearParseResult: true,
    );
  }

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

  Future<void> _recalculateAccountBalances() async {
    final recalculator = ref.read(recalculateBalancesProvider.notifier);
    await recalculator.calculatePreview();
    await recalculator.applyChanges();
  }

  void reset() {
    state = const FlexibleCsvImportState();
  }
}
