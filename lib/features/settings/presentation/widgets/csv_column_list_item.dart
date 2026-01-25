import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';

/// A list item representing a CSV column in the two-panel mapping view.
class CsvColumnListItem extends StatelessWidget {
  /// The name of the CSV column.
  final String columnName;

  /// Sample values from this column (2-3 values).
  final List<String> sampleValues;

  /// Whether this column is currently selected.
  final bool isSelected;

  /// The badge number if this column is mapped to a regular field (null if unmapped).
  final int? connectionBadge;

  /// Whether this column is mapped to a foreign key field (Category/Account).
  final bool isFkMapped;

  /// Callback when the item is tapped.
  final VoidCallback onTap;

  /// The color intensity for theming.
  final ColorIntensity intensity;

  const CsvColumnListItem({
    super.key,
    required this.columnName,
    required this.sampleValues,
    required this.isSelected,
    this.connectionBadge,
    this.isFkMapped = false,
    required this.onTap,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final isMapped = connectionBadge != null || isFkMapped;
    final accentColor = isFkMapped
        ? AppColors.getAccentColor(0, intensity)
        : _getBadgeColor(connectionBadge, intensity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : isMapped
                  ? accentColor.withValues(alpha: 0.08)
                  : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isSelected
                ? accentColor
                : isMapped
                    ? accentColor.withValues(alpha: 0.4)
                    : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Column name and samples
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    columnName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected || isMapped
                          ? accentColor
                          : AppColors.textPrimary,
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
            // Badge or FK indicator
            if (connectionBadge != null)
              _ConnectionBadge(
                number: connectionBadge!,
                intensity: intensity,
              )
            else if (isFkMapped)
              Icon(
                LucideIcons.link,
                size: 16,
                color: accentColor,
              ),
          ],
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
    final color = CsvColumnListItem._getBadgeColor(number, intensity);

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
