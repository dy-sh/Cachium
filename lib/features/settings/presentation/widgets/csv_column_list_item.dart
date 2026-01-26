import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import 'expandable_amount_item.dart' show getAmountColor;
import 'expandable_target_field_item.dart'
    show getFieldBadgeColor, getForeignKeyColor, getFieldIconByKey;

/// A list item representing a CSV column in the two-panel mapping view.
class CsvColumnListItem extends StatelessWidget {
  /// The name of the CSV column.
  final String columnName;

  /// Sample values from this column (2-3 values).
  final List<String> sampleValues;

  /// Whether this column is currently selected.
  final bool isSelected;

  /// Whether any field is currently selected (to highlight available items).
  final bool hasAnySelected;

  /// Whether this column is already mapped.
  final bool isMapped;

  /// Fixed color index if mapped to a regular field (based on field position).
  final int? mappedFieldColorIndex;

  /// The key of the field this column is mapped to (for icon selection).
  final String? mappedFieldKey;

  /// Which FK this column is mapped to ('category', 'account', or null).
  final String? fkMappedTo;

  /// Callback when the item is tapped.
  final VoidCallback onTap;

  /// The color intensity for theming.
  final ColorIntensity intensity;

  const CsvColumnListItem({
    super.key,
    required this.columnName,
    required this.sampleValues,
    required this.isSelected,
    this.hasAnySelected = false,
    this.isMapped = false,
    this.mappedFieldColorIndex,
    this.mappedFieldKey,
    this.fkMappedTo,
    required this.onTap,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final isAmountMapped = fkMappedTo == 'amount';
    final isFkMapped = fkMappedTo != null && fkMappedTo != 'amount';
    final isFieldMapped = mappedFieldColorIndex != null;
    // Available for mapping when a field is selected and this column is not mapped
    final isAvailable = hasAnySelected && !isMapped;
    // Dim mapped items when a field is selected
    final isDimmed = hasAnySelected && isMapped;

    final mappedColor = isAmountMapped
        ? getAmountColor(intensity)
        : isFkMapped
            ? getForeignKeyColor(fkMappedTo!, intensity)
            : isFieldMapped
                ? getFieldBadgeColor(mappedFieldColorIndex!, intensity)
                : AppColors.getAccentColor(0, intensity);

    // Get the icon for the mapped field (or FK/amount icon)
    final IconData? mappedIcon = isFieldMapped && mappedFieldKey != null
        ? getFieldIconByKey(mappedFieldKey!)
        : isAmountMapped
            ? LucideIcons.coins
            : isFkMapped
                ? (fkMappedTo == 'category' ? LucideIcons.tag : LucideIcons.wallet)
                : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? mappedColor.withValues(alpha: 0.15)
              : isMapped
                  ? mappedColor.withValues(alpha: isDimmed ? 0.03 : 0.08)
                  : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isSelected
                ? mappedColor
                : isMapped
                    ? mappedColor.withValues(alpha: isDimmed ? 0.2 : 0.5)
                    : isAvailable
                        ? AppColors.textSecondary
                        : AppColors.textTertiary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Opacity(
          opacity: isDimmed ? 0.4 : 1.0,
          child: Row(
            children: [
              // Icon on the left (when connected) or plus (when available)
              if (isMapped && mappedIcon != null) ...[
                Icon(
                  mappedIcon,
                  size: 16,
                  color: mappedColor,
                ),
                const SizedBox(width: AppSpacing.xs),
              ] else if (isAvailable) ...[
                Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              // Column name and samples
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      columnName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isMapped || isSelected || isAvailable ? FontWeight.w600 : FontWeight.w500,
                        color: isMapped || isSelected
                            ? AppColors.textPrimary
                            : isAvailable
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sampleValues.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatSampleValues(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSampleValues() {
    return sampleValues
        .take(2)
        .map((v) => v.length > 15 ? '${v.substring(0, 12)}...' : v)
        .join(', ');
  }
}
