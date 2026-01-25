import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flexible_csv_import_config.dart';
import '../providers/flexible_csv_import_providers.dart';
import '../providers/settings_provider.dart';
import 'csv_column_list_item.dart';
import 'expandable_target_field_item.dart';
import 'target_field_list_item.dart';

/// A two-panel view for mapping CSV columns to app fields.
/// Left panel: CSV columns with sample values
/// Right panel: Target app fields
class TwoPanelMappingView extends ConsumerWidget {
  /// The list of app field definitions.
  final List<AppFieldDefinition> fields;

  const TwoPanelMappingView({
    super.key,
    required this.fields,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flexibleCsvImportProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final selectedColumn = state.selectedCsvColumn;
    final expandedForeignKey = state.expandedForeignKey;

    if (state.config == null) return const SizedBox.shrink();

    final config = state.config!;
    final csvHeaders = config.csvHeaders;
    final isTransaction = config.entityType == ImportEntityType.transaction;

    // For transactions, filter out individual FK fields (we show consolidated Category/Account instead)
    final displayFields = isTransaction
        ? fields.where((f) => !f.isForeignKey).toList()
        : fields;

    // Build field color indices (fixed based on position in list)
    final fieldColorIndices = <String, int>{};
    for (var i = 0; i < displayFields.length; i++) {
      fieldColorIndices[displayFields[i].key] = i + 1; // 1-based for getFieldBadgeColor
    }

    // Build CSV column -> field info maps (for showing which field a column is mapped to)
    final csvColumnColorIndex = <String, int>{};
    final csvColumnFieldKey = <String, String>{};
    for (final field in displayFields) {
      final csvColumn = state.getCsvColumnForField(field.key);
      if (csvColumn != null) {
        csvColumnColorIndex[csvColumn] = fieldColorIndices[field.key]!;
        csvColumnFieldKey[csvColumn] = field.key;
      }
    }

    // Build the list of items for the right panel
    final rightPanelItems = <Widget>[];

    // For transactions, add Category and Account at the top
    if (isTransaction) {
      rightPanelItems.add(
        ExpandableForeignKeyItem(
          foreignKey: 'category',
          displayName: 'Category',
          icon: LucideIcons.tag,
          isExpanded: expandedForeignKey == 'category',
          onToggleExpand: () => _handleToggleForeignKey(ref, 'category'),
          intensity: intensity,
        ),
      );
      rightPanelItems.add(const SizedBox(height: AppSpacing.xs));
      rightPanelItems.add(
        ExpandableForeignKeyItem(
          foreignKey: 'account',
          displayName: 'Account',
          icon: LucideIcons.wallet,
          isExpanded: expandedForeignKey == 'account',
          onToggleExpand: () => _handleToggleForeignKey(ref, 'account'),
          intensity: intensity,
        ),
      );
      rightPanelItems.add(const SizedBox(height: AppSpacing.sm));
      rightPanelItems.add(
        Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
      );
      rightPanelItems.add(const SizedBox(height: AppSpacing.sm));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel - CSV Columns
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelHeader(
                title: 'CSV Columns',
                intensity: intensity,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  itemCount: csvHeaders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final column = csvHeaders[index];
                    final sampleValues = config.getSampleValues(column);
                    final isSelected = selectedColumn == column;

                    // Check which FK this column is mapped to (if any)
                    final categoryConfig = state.categoryConfig;
                    final accountConfig = state.accountConfig;
                    String? fkMappedTo;
                    if (column == categoryConfig.nameColumn ||
                        column == categoryConfig.idColumn) {
                      fkMappedTo = 'category';
                    } else if (column == accountConfig.nameColumn ||
                        column == accountConfig.idColumn) {
                      fkMappedTo = 'account';
                    }

                    // Get the fixed color index and field key from the mapped field (if mapped to a regular field)
                    final mappedColorIndex = csvColumnColorIndex[column];
                    final mappedFieldKey = csvColumnFieldKey[column];

                    return CsvColumnListItem(
                      columnName: column,
                      sampleValues: sampleValues,
                      isSelected: isSelected,
                      mappedFieldColorIndex: fkMappedTo != null ? null : mappedColorIndex,
                      mappedFieldKey: fkMappedTo != null ? null : mappedFieldKey,
                      fkMappedTo: fkMappedTo,
                      intensity: intensity,
                      onTap: () => _handleCsvColumnTap(
                        ref,
                        column,
                        mappedColorIndex,
                        fkMappedTo,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Right panel - Target Fields
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelHeader(
                title: 'Target Fields',
                intensity: intensity,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  children: [
                    // FK items (for transactions)
                    ...rightPanelItems,

                    // Regular fields
                    ...displayFields.map((field) {
                      final csvColumn = state.getCsvColumnForField(field.key);
                      final isMapped = csvColumn != null;
                      final colorIndex = fieldColorIndices[field.key]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: TargetFieldListItem(
                          fieldName: field.displayName,
                          fieldKey: field.key,
                          isRequired: field.isRequired,
                          isMapped: isMapped,
                          colorIndex: colorIndex,
                          hasCsvColumnSelected: selectedColumn != null,
                          intensity: intensity,
                          onTap: () =>
                              _handleFieldTap(ref, field.key, isMapped),
                        ),
                      );
                    }),

                    // Skip option
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: TargetFieldListItem(
                        fieldName: 'Skip',
                        isRequired: false,
                        isMapped: false,
                        hasCsvColumnSelected: selectedColumn != null,
                        intensity: intensity,
                        isSkipItem: true,
                        onTap: () => _handleSkipTap(ref),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleCsvColumnTap(
    WidgetRef ref,
    String column,
    int? mappedColorIndex,
    String? fkMappedTo,
  ) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    final selectedColumn = ref.read(flexibleCsvImportProvider).selectedCsvColumn;

    if (fkMappedTo != null) {
      // Clear from FK config
      final state = ref.read(flexibleCsvImportProvider);
      final config = fkMappedTo == 'category'
          ? state.categoryConfig
          : state.accountConfig;
      if (column == config.nameColumn) {
        notifier.clearForeignKeyField(fkMappedTo, 'name');
      } else if (column == config.idColumn) {
        notifier.clearForeignKeyField(fkMappedTo, 'id');
      }
    } else if (mappedColorIndex != null) {
      // Already mapped to a regular field - clear the connection
      notifier.clearConnectionForCsvColumn(column);
    } else if (selectedColumn == column) {
      // Already selected - deselect
      notifier.selectCsvColumn(null);
    } else {
      // Select this column
      notifier.selectCsvColumn(column);
    }
  }

  void _handleFieldTap(WidgetRef ref, String fieldKey, bool isMapped) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    final selectedColumn = ref.read(flexibleCsvImportProvider).selectedCsvColumn;

    if (isMapped) {
      // Already mapped - clear the connection
      notifier.clearConnectionForField(fieldKey);
    } else if (selectedColumn != null) {
      // Connect selected column to this field
      notifier.connectToField(fieldKey);
    }
    // If nothing selected and not mapped, do nothing
  }

  void _handleSkipTap(WidgetRef ref) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    // Just deselect the current column (skip it)
    notifier.selectCsvColumn(null);
  }

  void _handleToggleForeignKey(WidgetRef ref, String foreignKey) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    notifier.toggleExpandedForeignKey(foreignKey);
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final ColorIntensity intensity;

  const _PanelHeader({
    required this.title,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
