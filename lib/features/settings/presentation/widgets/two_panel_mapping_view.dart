import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flexible_csv_import_config.dart';
import '../providers/flexible_csv_import_providers.dart';
import '../providers/settings_provider.dart';
import 'csv_column_list_item.dart';
import 'target_field_list_item.dart';

/// A two-panel view for mapping CSV columns to app fields.
/// Left panel: CSV columns with sample values
/// Right panel: Target app fields
class TwoPanelMappingView extends ConsumerWidget {
  /// The list of app field definitions.
  final List<AppFieldDefinition> fields;

  /// Whether to show foreign key fields (category/account).
  final bool showForeignKeyFields;

  const TwoPanelMappingView({
    super.key,
    required this.fields,
    this.showForeignKeyFields = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flexibleCsvImportProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final selectedColumn = state.selectedCsvColumn;
    final badges = state.connectionBadges;

    if (state.config == null) return const SizedBox.shrink();

    final config = state.config!;
    final csvHeaders = config.csvHeaders;

    // Filter fields based on showForeignKeyFields
    final displayFields = showForeignKeyFields
        ? fields
        : fields.where((f) => !f.isForeignKey).toList();

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
                    final badge = badges[column];
                    final isSelected = selectedColumn == column;

                    return CsvColumnListItem(
                      columnName: column,
                      sampleValues: sampleValues,
                      isSelected: isSelected,
                      connectionBadge: badge,
                      intensity: intensity,
                      onTap: () => _handleCsvColumnTap(ref, column, badge),
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
                child: ListView.separated(
                  itemCount: displayFields.length + 1, // +1 for Skip option
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    // Skip option at the end
                    if (index == displayFields.length) {
                      return TargetFieldListItem(
                        fieldName: 'Skip',
                        isRequired: false,
                        isMapped: false,
                        hasCsvColumnSelected: selectedColumn != null,
                        intensity: intensity,
                        isSkipItem: true,
                        onTap: () => _handleSkipTap(ref),
                      );
                    }

                    final field = displayFields[index];
                    final csvColumn = state.getCsvColumnForField(field.key);
                    final badge = state.getBadgeForField(field.key);
                    final isMapped = csvColumn != null;

                    return TargetFieldListItem(
                      fieldName: field.displayName,
                      isRequired: field.isRequired,
                      isMapped: isMapped,
                      connectionBadge: badge,
                      hasCsvColumnSelected: selectedColumn != null,
                      intensity: intensity,
                      onTap: () => _handleFieldTap(ref, field.key, isMapped),
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

  void _handleCsvColumnTap(WidgetRef ref, String column, int? badge) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    final selectedColumn = ref.read(flexibleCsvImportProvider).selectedCsvColumn;

    if (badge != null) {
      // Already mapped - clear the connection
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
