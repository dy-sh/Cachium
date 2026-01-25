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

  const FieldMappingTile({
    super.key,
    required this.field,
    required this.mapping,
    required this.csvHeaders,
    required this.sampleValues,
    required this.onColumnChanged,
    this.onStrategyChanged,
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
          color: isMapped ? accentColor.withValues(alpha: 0.3) : AppColors.border,
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
                      if (field.isRequired && !field.isForeignKey) ...[
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w600,
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
                bottom: AppSpacing.md,
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
                  Text(
                    sampleValues.map((v) {
                      return v.length > 25 ? '${v.substring(0, 22)}...' : v;
                    }).join(', '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isMapped, ColorIntensity intensity) {
    if (isMapped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.income.withValues(alpha: 0.15),
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
          color: AppColors.cyan.withValues(alpha: 0.15),
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
          color: AppColors.yellow.withValues(alpha: 0.15),
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
          color: AppColors.textTertiary.withValues(alpha: 0.15),
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
        color: AppColors.expense.withValues(alpha: 0.15),
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
        color: AppColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
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
}
