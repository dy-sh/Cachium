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

                    // Field mappings
                    Text(
                      'FIELD MAPPINGS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    ...fields.map((field) {
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
                        onFkStrategyChanged: field.isForeignKey
                            ? (strategy) {
                                ref.read(flexibleCsvImportProvider.notifier)
                                    .updateFieldMapping(
                                      fieldKey: field.key,
                                      fkStrategy: strategy,
                                    );
                              }
                            : null,
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
              color: AppColors.getAccentColor(0, intensity).withOpacity(0.15),
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
                      ? AppColors.getAccentColor(0, intensity).withOpacity(0.15)
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
        color: AppColors.textTertiary.withOpacity(0.05),
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
