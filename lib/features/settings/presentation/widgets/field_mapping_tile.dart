import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flexible_csv_import_config.dart';
import '../providers/settings_provider.dart';

/// Widget for mapping a single app field to a CSV column.
class FieldMappingTile extends ConsumerWidget {
  final AppFieldDefinition field;
  final FieldMapping mapping;
  final List<String> csvHeaders;
  final List<String> sampleValues;
  final ValueChanged<String?> onColumnChanged;
  final ValueChanged<MissingFieldStrategy>? onStrategyChanged;
  final ValueChanged<ForeignKeyMatchStrategy>? onFkStrategyChanged;
  final bool showFkOptions;

  const FieldMappingTile({
    super.key,
    required this.field,
    required this.mapping,
    required this.csvHeaders,
    required this.sampleValues,
    required this.onColumnChanged,
    this.onStrategyChanged,
    this.onFkStrategyChanged,
    this.showFkOptions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColor = AppColors.getAccentColor(0, intensity);
    final isMapped = mapping.csvColumn != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isMapped ? accentColor.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Field name with required indicator
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        field.displayName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (field.isRequired) ...[
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (field.isForeignKey) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FK',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.cyan,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Mapping status
                _buildStatusChip(isMapped, intensity),
              ],
            ),
          ),

          // Description
          if (field.description != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                field.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),

          // Divider
          Divider(color: AppColors.border, height: 1),

          // Column selector
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSV Column',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildColumnDropdown(accentColor),
              ],
            ),
          ),

          // Sample values (if mapped)
          if (isMapped && sampleValues.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample values',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sampleValues.map((v) {
                      final displayValue = v.length > 30 ? '${v.substring(0, 27)}...' : v;
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
                          displayValue,
                          style: AppTypography.bodySmall.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // ID field strategy (when not mapped)
          if (!isMapped && field.isId && onStrategyChanged != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: _buildIdStrategyChip(),
            ),
          ],

          // FK strategy selector
          if (showFkOptions && field.isForeignKey && isMapped && onFkStrategyChanged != null) ...[
            Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match by',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildFkStrategySelector(intensity),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isMapped, ColorIntensity intensity) {
    if (isMapped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.income.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 12, color: AppColors.income),
            const SizedBox(width: 4),
            Text(
              'Mapped',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.income,
              ),
            ),
          ],
        ),
      );
    }

    if (field.isId && mapping.missingStrategy == MissingFieldStrategy.generateId) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 12, color: AppColors.cyan),
            const SizedBox(width: 4),
            Text(
              'Auto-generate',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.cyan,
              ),
            ),
          ],
        ),
      );
    }

    if (field.defaultValue != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.yellow.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Default',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.yellow,
          ),
        ),
      );
    }

    if (!field.isRequired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Optional',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.expense.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Required',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.expense,
        ),
      ),
    );
  }

  Widget _buildColumnDropdown(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.input,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: mapping.csvColumn,
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
            ...csvHeaders.map((header) {
              return DropdownMenuItem<String?>(
                value: header,
                child: Text(
                  header,
                  style: AppTypography.bodyMedium,
                ),
              );
            }),
          ],
          onChanged: onColumnChanged,
        ),
      ),
    );
  }

  Widget _buildIdStrategyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.sparkles, size: 16, color: AppColors.cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'IDs will be generated automatically',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFkStrategySelector(ColorIntensity intensity) {
    final strategies = [
      ForeignKeyMatchStrategy.byName,
      ForeignKeyMatchStrategy.byId,
      ForeignKeyMatchStrategy.createIfMissing,
      ForeignKeyMatchStrategy.useDefault,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: strategies.map((strategy) {
        final isSelected = mapping.fkStrategy == strategy;
        return GestureDetector(
          onTap: () => onFkStrategyChanged?.call(strategy),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.getAccentColor(0, intensity).withOpacity(0.15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.getAccentColor(0, intensity)
                    : AppColors.border,
              ),
            ),
            child: Text(
              strategy.displayName,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.getAccentColor(0, intensity)
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
