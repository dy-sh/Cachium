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

  /// Fixed color index for this field (based on field position, doesn't change).
  final int colorIndex;

  /// Whether a CSV column is currently selected (for visual feedback).
  final bool hasCsvColumnSelected;

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
    this.colorIndex = 0,
    this.hasCsvColumnSelected = false,
    required this.onTap,
    required this.intensity,
    this.isSkipItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final fieldColor = getFieldBadgeColor(colorIndex, intensity);
    final fieldIcon = getFieldIconByKey(fieldKey);
    final canReceiveMapping = hasCsvColumnSelected && !isMapped;
    // Dim mapped items when selecting to highlight available options
    final isDimmed = hasCsvColumnSelected && isMapped;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isMapped
              ? fieldColor.withValues(alpha: isDimmed ? 0.03 : 0.08)
              : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isMapped
                ? fieldColor.withValues(alpha: isDimmed ? 0.2 : 0.5)
                : canReceiveMapping
                    ? AppColors.textPrimary
                    : AppColors.border,
            width: isMapped || canReceiveMapping ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: isDimmed ? 0.4 : 1.0,
          child: Row(
            children: [
              // Icon marker on the left (always visible)
              if (!isSkipItem) ...[
                Icon(
                  fieldIcon,
                  size: 16,
                  color: isMapped
                      ? fieldColor
                      : canReceiveMapping
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ] else ...[
                Icon(
                  LucideIcons.skipForward,
                  size: 16,
                  color: canReceiveMapping ? AppColors.textPrimary : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              // Field name (bright when available, dimmed when disconnected)
              Expanded(
                child: Row(
                  children: [
                    Text(
                      fieldName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isMapped || canReceiveMapping ? FontWeight.w600 : FontWeight.w500,
                        color: isSkipItem
                            ? AppColors.textTertiary
                            : isMapped
                                ? AppColors.textPrimary
                                : canReceiveMapping
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
              ),
              // Plus icon when can receive mapping
              if (canReceiveMapping)
                Icon(
                  LucideIcons.plus,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
