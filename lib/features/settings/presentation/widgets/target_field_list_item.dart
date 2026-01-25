import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';

/// A list item representing a target app field in the two-panel mapping view.
class TargetFieldListItem extends StatelessWidget {
  /// The display name of the field.
  final String fieldName;

  /// Whether this field is required.
  final bool isRequired;

  /// Whether this field is already mapped to a CSV column.
  final bool isMapped;

  /// The badge number if mapped (null if unmapped).
  final int? connectionBadge;

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
    this.isRequired = false,
    this.isMapped = false,
    this.connectionBadge,
    this.hasCsvColumnSelected = false,
    required this.onTap,
    required this.intensity,
    this.isSkipItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = _getBadgeColor(connectionBadge, intensity);
    final canReceiveMapping = hasCsvColumnSelected && !isMapped;

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
              ? accentColor.withValues(alpha: 0.08)
              : canReceiveMapping
                  ? AppColors.getAccentColor(0, intensity).withValues(alpha: 0.05)
                  : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isMapped
                ? accentColor.withValues(alpha: 0.4)
                : canReceiveMapping
                    ? AppColors.getAccentColor(0, intensity).withValues(alpha: 0.3)
                    : AppColors.border,
            width: canReceiveMapping ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Field name
            Expanded(
              child: Row(
                children: [
                  if (isSkipItem) ...[
                    Icon(
                      LucideIcons.skipForward,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    fieldName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isMapped ? FontWeight.w600 : FontWeight.w500,
                      color: isSkipItem
                          ? AppColors.textTertiary
                          : isMapped
                              ? accentColor
                              : AppColors.textPrimary,
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
            // Badge or indicator
            if (isMapped && connectionBadge != null)
              _ConnectionBadge(
                number: connectionBadge!,
                intensity: intensity,
              )
            else if (canReceiveMapping)
              Icon(
                LucideIcons.plus,
                size: 18,
                color: AppColors.getAccentColor(0, intensity).withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  static Color _getBadgeColor(int? badge, ColorIntensity intensity) {
    if (badge == null) return AppColors.getAccentColor(0, intensity);
    // Cycle through accent colors (skip index 0 which is white)
    final colorIndex = ((badge - 1) % 6) + 1;
    return AppColors.getAccentColor(colorIndex, intensity);
  }
}

/// A numbered badge showing the connection number.
class _ConnectionBadge extends StatelessWidget {
  final int number;
  final ColorIntensity intensity;

  const _ConnectionBadge({
    required this.number,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final color = TargetFieldListItem._getBadgeColor(number, intensity);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.background,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
