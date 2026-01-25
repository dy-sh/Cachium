import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flexible_csv_import_config.dart';
import '../../data/models/import_preset.dart';
import '../providers/flexible_csv_import_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/field_mapping_tile.dart';

/// Screen for mapping CSV columns to app fields.
class ColumnMappingScreen extends ConsumerWidget {
  const ColumnMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flexibleCsvImportProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final canProceed = ref.watch(canProceedToPreviewProvider);
    final fileName = ref.watch(currentCsvFileNameProvider);

    if (state.config == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final config = state.config!;
    final fields = ImportFieldDefinitions.getFieldsForType(config.entityType);
    final presets = BuiltInPresets.getPresetsForType(config.entityType);
    final isTransaction = config.entityType == ImportEntityType.transaction;

    // Filter out FK fields for transactions - they're handled separately
    final regularFields = isTransaction
        ? fields.where((f) => !f.isForeignKey).toList()
        : fields;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(flexibleCsvImportProvider.notifier).goBackToTypeSelection();
                          context.pop();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Map Columns', style: AppTypography.h3),
                            if (fileName != null)
                              Text(
                                fileName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File info card
                    _buildFileInfoCard(config, intensity),
                    const SizedBox(height: AppSpacing.lg),

                    // Preset selector (if available)
                    if (presets.isNotEmpty) ...[
                      _buildPresetSelector(ref, presets, state.appliedPreset, intensity),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Category/Account selection for transactions
                    if (isTransaction) ...[
                      _buildCategoryAccountSection(context, ref, state, config, intensity),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Field mappings
                    Text(
                      'FIELD MAPPINGS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    ...regularFields.map((field) {
                      final mapping = config.fieldMappings[field.key];
                      if (mapping == null) return const SizedBox.shrink();

                      final sampleValues = mapping.csvColumn != null
                          ? config.getSampleValues(mapping.csvColumn!)
                          : <String>[];

                      return FieldMappingTile(
                        field: field,
                        mapping: mapping,
                        csvHeaders: config.csvHeaders,
                        sampleValues: sampleValues,
                        onColumnChanged: (column) {
                          ref.read(flexibleCsvImportProvider.notifier)
                              .updateFieldMapping(
                                fieldKey: field.key,
                                csvColumn: column,
                                clearCsvColumn: column == null,
                              );
                        },
                        onStrategyChanged: (strategy) {
                          ref.read(flexibleCsvImportProvider.notifier)
                              .updateFieldMapping(
                                fieldKey: field.key,
                                missingStrategy: strategy,
                              );
                        },
                      );
                    }),

                    // Unmapped columns info
                    if (state.unmappedCsvColumns.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildUnmappedColumnsCard(state.unmappedCsvColumns),
                    ],

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // Bottom action
            _buildBottomAction(context, ref, canProceed, state.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAccountSection(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
    FlexibleCsvImportConfig config,
    ColorIntensity intensity,
  ) {
    final accentColor = AppColors.getAccentColor(0, intensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY & ACCOUNT',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Category section
        _buildEntitySection(
          context: context,
          ref: ref,
          title: 'Category',
          icon: LucideIcons.tag,
          useSameForAll: state.useSameCategoryForAll,
          onUseSameChanged: (value) {
            ref.read(flexibleCsvImportProvider.notifier).setUseSameCategoryForAll(value);
          },
          selectedEntityId: state.defaultCategoryId,
          onEntitySelected: (id) {
            ref.read(flexibleCsvImportProvider.notifier).setDefaultCategory(id);
          },
          buildEntityPicker: () => _buildCategoryPicker(context, ref, state, intensity),
          config: config,
          idFieldKey: 'categoryId',
          nameFieldKey: 'categoryName',
          accentColor: accentColor,
          intensity: intensity,
        ),

        const SizedBox(height: AppSpacing.md),

        // Account section
        _buildEntitySection(
          context: context,
          ref: ref,
          title: 'Account',
          icon: LucideIcons.wallet,
          useSameForAll: state.useSameAccountForAll,
          onUseSameChanged: (value) {
            ref.read(flexibleCsvImportProvider.notifier).setUseSameAccountForAll(value);
          },
          selectedEntityId: state.defaultAccountId,
          onEntitySelected: (id) {
            ref.read(flexibleCsvImportProvider.notifier).setDefaultAccount(id);
          },
          buildEntityPicker: () => _buildAccountPicker(context, ref, state, intensity),
          config: config,
          idFieldKey: 'accountId',
          nameFieldKey: 'accountName',
          accentColor: accentColor,
          intensity: intensity,
        ),
      ],
    );
  }

  Widget _buildEntitySection({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required bool useSameForAll,
    required ValueChanged<bool> onUseSameChanged,
    required String? selectedEntityId,
    required ValueChanged<String?> onEntitySelected,
    required Widget Function() buildEntityPicker,
    required FlexibleCsvImportConfig config,
    required String idFieldKey,
    required String nameFieldKey,
    required Color accentColor,
    required ColorIntensity intensity,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with checkbox
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 20, color: accentColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Checkbox for "use same for all"
                GestureDetector(
                  onTap: () => onUseSameChanged(!useSameForAll),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: useSameForAll
                              ? accentColor
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: useSameForAll ? accentColor : AppColors.border,
                          ),
                        ),
                        child: useSameForAll
                            ? Icon(LucideIcons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Same for all',
                        style: AppTypography.bodySmall.copyWith(
                          color: useSameForAll ? accentColor : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.border, height: 1),

          // Content based on mode
          if (useSameForAll) ...[
            // Show entity picker
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select $title',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  buildEntityPicker(),
                ],
              ),
            ),
          ] else ...[
            // Show column mapping dropdowns
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID mapping
                  _buildFkFieldMapping(
                    ref: ref,
                    label: '$title ID',
                    description: 'Map to UUID column (optional)',
                    fieldKey: idFieldKey,
                    config: config,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Name mapping
                  _buildFkFieldMapping(
                    ref: ref,
                    label: '$title Name',
                    description: 'Map to name column (will create if not found)',
                    fieldKey: nameFieldKey,
                    config: config,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFkFieldMapping({
    required WidgetRef ref,
    required String label,
    required String description,
    required String fieldKey,
    required FlexibleCsvImportConfig config,
  }) {
    final mapping = config.fieldMappings[fieldKey];
    final isMapped = mapping?.csvColumn != null;
    final sampleValues = mapping?.csvColumn != null
        ? config.getSampleValues(mapping!.csvColumn!)
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isMapped) ...[
              const SizedBox(width: 8),
              Icon(LucideIcons.check, size: 14, color: AppColors.income),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.input,
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: mapping?.csvColumn,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 18),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              dropdownColor: AppColors.surface,
              borderRadius: AppRadius.card,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'Not mapped',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                ...config.csvHeaders.map((header) {
                  return DropdownMenuItem<String?>(
                    value: header,
                    child: Text(header, style: AppTypography.bodyMedium),
                  );
                }),
              ],
              onChanged: (column) {
                ref.read(flexibleCsvImportProvider.notifier).updateFieldMapping(
                  fieldKey: fieldKey,
                  csvColumn: column,
                  clearCsvColumn: column == null,
                );
              },
            ),
          ),
        ),
        if (isMapped && sampleValues.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            sampleValues.map((v) => v.length > 20 ? '${v.substring(0, 17)}...' : v).join(', '),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
    ColorIntensity intensity,
  ) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final selectedCategory = state.defaultCategoryId != null
            ? categories.where((c) => c.id == state.defaultCategoryId).firstOrNull
            : null;

        return GestureDetector(
          onTap: () => _showCategoryPicker(context, ref, categories, state.defaultCategoryId),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.input,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                if (selectedCategory != null) ...[
                  Icon(selectedCategory.icon, size: 20, color: AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      selectedCategory.name,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ] else ...[
                  Icon(LucideIcons.tag, size: 20, color: AppColors.textTertiary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Select category...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text('Failed to load categories', style: AppTypography.bodySmall),
    );
  }

  Widget _buildAccountPicker(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
    ColorIntensity intensity,
  ) {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        final selectedAccount = state.defaultAccountId != null
            ? accounts.where((a) => a.id == state.defaultAccountId).firstOrNull
            : null;

        return GestureDetector(
          onTap: () => _showAccountPicker(context, ref, accounts, state.defaultAccountId),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.input,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                if (selectedAccount != null) ...[
                  Icon(selectedAccount.icon, size: 20, color: AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      selectedAccount.name,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ] else ...[
                  Icon(LucideIcons.wallet, size: 20, color: AppColors.textTertiary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Select account...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text('Failed to load accounts', style: AppTypography.bodySmall),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
    String? selectedId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('Select Category', style: AppTypography.h4),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.id == selectedId;
                    return ListTile(
                      leading: Icon(
                        category.icon,
                        color: isSelected ? AppColors.income : AppColors.textSecondary,
                      ),
                      title: Text(
                        category.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected ? AppColors.income : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(LucideIcons.check, color: AppColors.income)
                          : null,
                      onTap: () {
                        ref.read(flexibleCsvImportProvider.notifier)
                            .setDefaultCategory(category.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountPicker(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
    String? selectedId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('Select Account', style: AppTypography.h4),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final isSelected = account.id == selectedId;
                    return ListTile(
                      leading: Icon(
                        account.icon,
                        color: isSelected ? AppColors.income : AppColors.textSecondary,
                      ),
                      title: Text(
                        account.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected ? AppColors.income : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(LucideIcons.check, color: AppColors.income)
                          : null,
                      onTap: () {
                        ref.read(flexibleCsvImportProvider.notifier)
                            .setDefaultAccount(account.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileInfoCard(FlexibleCsvImportConfig config, ColorIntensity intensity) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.getAccentColor(0, intensity).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.fileSpreadsheet,
              size: 20,
              color: AppColors.getAccentColor(0, intensity),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${config.csvRows.length} rows',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${config.csvHeaders.length} columns',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              config.entityType.displayName,
              style: AppTypography.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(
    WidgetRef ref,
    List<ImportPreset> presets,
    ImportPreset? appliedPreset,
    ColorIntensity intensity,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK PRESETS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            final isApplied = appliedPreset?.id == preset.id;
            return GestureDetector(
              onTap: () {
                ref.read(flexibleCsvImportProvider.notifier).applyPreset(preset);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isApplied
                      ? AppColors.getAccentColor(0, intensity).withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isApplied
                        ? AppColors.getAccentColor(0, intensity)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isApplied) ...[
                      Icon(
                        LucideIcons.check,
                        size: 14,
                        color: AppColors.getAccentColor(0, intensity),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      preset.name,
                      style: AppTypography.bodySmall.copyWith(
                        color: isApplied
                            ? AppColors.getAccentColor(0, intensity)
                            : AppColors.textPrimary,
                        fontWeight: isApplied ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUnmappedColumnsCard(List<String> unmappedColumns) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Unmapped CSV columns',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: unmappedColumns.map((col) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  col,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'These columns will be ignored during import',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    WidgetRef ref,
    bool canProceed,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: 'Preview Import',
          onPressed: canProceed && !isLoading
              ? () async {
                  final success = await ref
                      .read(flexibleCsvImportProvider.notifier)
                      .generatePreview();
                  if (success && context.mounted) {
                    context.push(AppRoutes.csvImportPreview);
                  } else if (!success && context.mounted) {
                    final error = ref.read(flexibleCsvImportProvider).error;
                    if (error != null) {
                      context.showErrorNotification(error);
                    }
                  }
                }
              : null,
          isLoading: isLoading,
        ),
      ),
    );
  }
}
