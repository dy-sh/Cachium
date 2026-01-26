import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import 'expandable_target_field_item.dart' show getFieldBadgeColor, getFieldIconByKey;

/// A list item representing a target app field in the two-panel mapping view.
class TargetFieldListItem extends StatelessWidget {
  /// The display name of the field.
  final String fieldName;

  /// The key of the field (used for icon selection).
  final String fieldKey;

  /// Whether this field is required.
  final bool isRequired;

  /// Whether this field is already mapped to a CSV column.
  final bool isMapped;

  /// The name of the mapped CSV column (if mapped).
  final String? mappedCsvColumn;

  /// Whether this field is currently selected.
  final bool isSelected;

  /// Fixed color index for this field (based on field position, doesn't change).
  final int colorIndex;

  /// Whether any field is currently selected (for dimming other items).
  final bool hasAnySelected;

  /// Callback when the item is tapped.
  final VoidCallback onTap;

  /// The color intensity for theming.
  final ColorIntensity intensity;

  /// Whether this is a special "Skip" item.
  final bool isSkipItem;

  const TargetFieldListItem({
    super.key,
    required this.fieldName,
    this.fieldKey = '',
    this.isRequired = false,
    this.isMapped = false,
    this.mappedCsvColumn,
    this.isSelected = false,
    this.colorIndex = 0,
    this.hasAnySelected = false,
    required this.onTap,
    required this.intensity,
    this.isSkipItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final fieldColor = getFieldBadgeColor(colorIndex, intensity);
    final fieldIcon = getFieldIconByKey(fieldKey);
    // Dim other items when this field or another is selected
    final isDimmed = hasAnySelected && !isSelected && !isMapped;
    // Dim mapped items more when selecting
    final isMappedDimmed = hasAnySelected && !isSelected && isMapped;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? fieldColor.withValues(alpha: 0.15)
              : isMapped
                  ? fieldColor.withValues(alpha: isMappedDimmed ? 0.03 : 0.08)
                  : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isSelected
                ? fieldColor
                : isMapped
                    ? fieldColor.withValues(alpha: isMappedDimmed ? 0.2 : 0.5)
                    : AppColors.textTertiary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Opacity(
          opacity: isDimmed || isMappedDimmed ? 0.4 : 1.0,
          child: Row(
            children: [
              // Field name and mapped column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fieldName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isMapped || isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSkipItem
                                ? AppColors.textTertiary
                                : isMapped || isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                          ),
                        ),
                        // Required indicator
                        if (isRequired && !isMapped && !isSkipItem) ...[
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
                    // Show mapped CSV column name, reserve space when not mapped
                    Text(
                      isMapped && mappedCsvColumn != null ? '"$mappedCsvColumn"' : '',
                      style: AppTypography.labelSmall.copyWith(
                        color: fieldColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Icon marker on the right (always visible)
              if (!isSkipItem) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  fieldIcon,
                  size: 16,
                  color: isMapped || isSelected ? fieldColor : AppColors.textTertiary,
                ),
              ] else ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  LucideIcons.skipForward,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
