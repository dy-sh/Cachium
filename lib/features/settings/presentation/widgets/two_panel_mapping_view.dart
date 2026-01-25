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
/// Left panel: Target app fields
/// Right panel: CSV columns with sample values
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
    final selectedFieldKey = state.selectedFieldKey;
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

    // Build the list of items for the left panel (target fields)
    final leftPanelItems = <Widget>[];

    // For transactions, add Category and Account at the top
    if (isTransaction) {
      leftPanelItems.add(
        ExpandableForeignKeyItem(
          foreignKey: 'category',
          displayName: 'Category',
          icon: LucideIcons.tag,
          isExpanded: expandedForeignKey == 'category',
          onToggleExpand: () => _handleToggleForeignKey(ref, 'category'),
          intensity: intensity,
          hasCsvColumnSelected: selectedFieldKey != null,
        ),
      );
      leftPanelItems.add(const SizedBox(height: AppSpacing.xs));
      leftPanelItems.add(
        ExpandableForeignKeyItem(
          foreignKey: 'account',
          displayName: 'Account',
          icon: LucideIcons.wallet,
          isExpanded: expandedForeignKey == 'account',
          onToggleExpand: () => _handleToggleForeignKey(ref, 'account'),
          intensity: intensity,
          hasCsvColumnSelected: selectedFieldKey != null,
        ),
      );
      leftPanelItems.add(const SizedBox(height: AppSpacing.sm));
      leftPanelItems.add(
        Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
      );
      leftPanelItems.add(const SizedBox(height: AppSpacing.sm));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel - Target Fields
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
                    ...leftPanelItems,

                    // Regular fields
                    ...displayFields.map((field) {
                      final csvColumn = state.getCsvColumnForField(field.key);
                      final isMapped = csvColumn != null;
                      final colorIndex = fieldColorIndices[field.key]!;
                      final isSelected = selectedFieldKey == field.key;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: TargetFieldListItem(
                          fieldName: field.displayName,
                          fieldKey: field.key,
                          isRequired: field.isRequired,
                          isMapped: isMapped,
                          isSelected: isSelected,
                          colorIndex: colorIndex,
                          hasAnySelected: selectedFieldKey != null,
                          intensity: intensity,
                          onTap: () => _handleFieldTap(ref, field.key, isMapped, isSelected),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Right panel - CSV Columns
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
                    final isMapped = mappedColorIndex != null || fkMappedTo != null;

                    return CsvColumnListItem(
                      columnName: column,
                      sampleValues: sampleValues,
                      isSelected: false, // CSV columns are not selectable anymore
                      hasAnySelected: selectedFieldKey != null,
                      isMapped: isMapped,
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
      ],
    );
  }

  void _handleFieldTap(WidgetRef ref, String fieldKey, bool isMapped, bool isSelected) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);

    if (isMapped) {
      // Already mapped - clear the connection
      notifier.clearConnectionForField(fieldKey);
    } else if (isSelected) {
      // Already selected - deselect
      notifier.selectField(null);
    } else {
      // Select this field
      notifier.selectField(fieldKey);
    }
  }

  void _handleCsvColumnTap(
    WidgetRef ref,
    String column,
    int? mappedColorIndex,
    String? fkMappedTo,
  ) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    final state = ref.read(flexibleCsvImportProvider);
    final selectedFieldKey = state.selectedFieldKey;

    if (fkMappedTo != null) {
      // Already mapped to FK - clear from FK config
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
    } else if (selectedFieldKey != null) {
      // A field is selected - connect this CSV column to it
      if (selectedFieldKey.startsWith('fk:')) {
        // Selected field is a FK sub-field
        notifier.connectCsvColumnToForeignKey(column);
      } else {
        // Selected field is a regular field
        notifier.connectToCsvColumn(column);
      }
    }
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
