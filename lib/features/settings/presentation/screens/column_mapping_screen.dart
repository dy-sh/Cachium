import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flexible_csv_import_config.dart';
import '../../data/models/import_preset.dart';
import '../providers/flexible_csv_import_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/two_panel_mapping_view.dart';

/// Screen for mapping CSV columns to app fields using a two-panel layout.
class ColumnMappingScreen extends ConsumerWidget {
  const ColumnMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flexibleCsvImportProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final canProceed = ref.watch(canProceedToPreviewProvider);
    final fileName = ref.watch(currentCsvFileNameProvider);
    final progress = ref.watch(mappingProgressProvider);

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
            _buildHeader(
              context,
              ref,
              fileName,
              progress,
              intensity,
              canProceed,
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File info and preset row
                    _buildFileInfoAndPresetRow(
                      context,
                      ref,
                      config,
                      presets,
                      state.appliedPreset,
                      intensity,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Two-panel mapping view (now includes FK fields inline)
                    Expanded(
                      child: TwoPanelMappingView(
                        fields: fields,
                      ),
                    ),
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

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String? fileName,
    (int, int) progress,
    ColorIntensity intensity,
    bool canProceed,
  ) {
    final (mapped, total) = progress;
    final accentColor = AppColors.getAccentColor(0, intensity);
    final progressColor = canProceed ? AppColors.income : accentColor;

    return Padding(
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
                  ref
                      .read(flexibleCsvImportProvider.notifier)
                      .goBackToTypeSelection();
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
              // Progress badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$mapped/$total',
                  style: AppTypography.labelSmall.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildFileInfoAndPresetRow(
    BuildContext context,
    WidgetRef ref,
    FlexibleCsvImportConfig config,
    List<ImportPreset> presets,
    ImportPreset? appliedPreset,
    ColorIntensity intensity,
  ) {
    return Row(
      children: [
        // Preset selector (on left)
        if (presets.isNotEmpty)
          _buildPresetSelector(
            context,
            ref,
            presets,
            appliedPreset,
            intensity,
          ),
        const Spacer(),
        // Compact file stats badges (on right)
        _buildStatBadge(
          icon: LucideIcons.alignJustify,
          value: '${config.csvRows.length}',
          label: 'rows',
        ),
        const SizedBox(width: AppSpacing.xs),
        _buildStatBadge(
          icon: LucideIcons.columns,
          value: '${config.csvHeaders.length}',
          label: 'cols',
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(
    BuildContext context,
    WidgetRef ref,
    List<ImportPreset> presets,
    ImportPreset? appliedPreset,
    ColorIntensity intensity,
  ) {
    final accentColor = AppColors.getAccentColor(0, intensity);
    final hasPreset = appliedPreset != null;

    return GestureDetector(
      onTap: () => _showPresetPicker(context, ref, presets, appliedPreset),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: hasPreset
              ? accentColor.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasPreset ? accentColor : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 14,
              color: hasPreset ? accentColor : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              'Preset',
              style: AppTypography.labelSmall.copyWith(
                color: hasPreset ? accentColor : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: hasPreset
                    ? accentColor.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hasPreset ? appliedPreset.name : 'None',
                style: AppTypography.labelSmall.copyWith(
                  color: hasPreset ? accentColor : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: hasPreset ? accentColor : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetPicker(
    BuildContext context,
    WidgetRef ref,
    List<ImportPreset> presets,
    ImportPreset? appliedPreset,
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
                child: Text('Quick Presets', style: AppTypography.h4),
              ),
              const SizedBox(height: AppSpacing.md),
              // Clear option
              ListTile(
                leading: Icon(
                  LucideIcons.eraser,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  'Clear',
                  style: AppTypography.bodyMedium,
                ),
                subtitle: Text(
                  'Remove all column bindings',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                onTap: () {
                  ref
                      .read(flexibleCsvImportProvider.notifier)
                      .clearAllMappings();
                  Navigator.pop(context);
                },
              ),
              // Automatic option
              ListTile(
                leading: Icon(
                  LucideIcons.wand2,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  'Automatic',
                  style: AppTypography.bodyMedium,
                ),
                subtitle: Text(
                  'Auto-detect column mappings',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                onTap: () {
                  ref
                      .read(flexibleCsvImportProvider.notifier)
                      .applyAutoDetect();
                  Navigator.pop(context);
                },
              ),
              // Built-in presets
              ...presets.map((preset) {
                final isApplied = appliedPreset?.id == preset.id;
                return ListTile(
                  leading: Icon(
                    isApplied ? LucideIcons.check : LucideIcons.sparkles,
                    color:
                        isApplied ? AppColors.income : AppColors.textSecondary,
                  ),
                  title: Text(
                    preset.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color:
                          isApplied ? AppColors.income : AppColors.textPrimary,
                      fontWeight:
                          isApplied ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: preset.description.isNotEmpty
                      ? Text(
                          preset.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(flexibleCsvImportProvider.notifier)
                        .applyPreset(preset);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
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
