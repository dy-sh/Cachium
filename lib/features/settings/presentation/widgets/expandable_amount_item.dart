import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../providers/flexible_csv_import_providers.dart';
import 'amount_options_panel.dart';

/// Color index for Amount field (green - index 9).
const int amountColorIndex = 9;

/// Get the color for the amount section.
Color getAmountColor(ColorIntensity intensity) {
  return AppColors.getAccentColor(amountColorIndex, intensity);
}

/// An expandable item for Amount/Type configuration.
/// Shows a summary when collapsed, expands to show mapping options.
class ExpandableAmountItem extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ColorIntensity intensity;
  final bool hasCsvColumnSelected;

  /// Whether this item should be highlighted (e.g., paired preview).
  final bool isHighlighted;

  /// Optional callback to get a GlobalKey for position tracking.
  final GlobalKey Function(String key)? getPositionKey;

  /// Callback when a sub-field preview starts (long press).
  final void Function(String key)? onPreviewStart;

  /// Callback when a sub-field preview ends.
  final VoidCallback? onPreviewEnd;

  const ExpandableAmountItem({
    super.key,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.intensity,
    this.hasCsvColumnSelected = false,
    this.isHighlighted = false,
    this.getPositionKey,
    this.onPreviewStart,
    this.onPreviewEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(amountConfigProvider);
    final accentColor = getAmountColor(intensity);
    final isConfigured = config.isValid;
    // Dim configured items when selecting another field (but not if highlighted)
    final isDimmed = hasCsvColumnSelected && !isExpanded && !isHighlighted;
    // Show as active when configured or highlighted
    final showActive = isConfigured || isHighlighted;

    // Get summary text
    final summary = config.getDisplaySummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        GestureDetector(
          onTap: onToggleExpand,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: showActive
                  ? accentColor.withValues(alpha: isDimmed ? 0.03 : 0.08)
                  : AppColors.surface,
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : AppRadius.card,
              border: Border.all(
                color: showActive
                    ? accentColor.withValues(alpha: isDimmed ? 0.2 : 0.4)
                    : AppColors.textTertiary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Opacity(
              opacity: isDimmed ? 0.4 : 1.0,
              child: Row(
                children: [
                  // Expand/collapse icon on the left
                  Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: showActive ? accentColor : AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Name and summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Amount',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: showActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: showActive
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            // Required indicator
                            if (!isConfigured) ...[
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
                        if (!isExpanded)
                          Text(
                            summary,
                            style: AppTypography.labelSmall.copyWith(
                              color: showActive
                                  ? accentColor
                                  : AppColors.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Icon on the right
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    LucideIcons.coins,
                    size: 18,
                    color: showActive ? accentColor : AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expanded options panel
        if (isExpanded)
          AmountOptionsPanel(
            intensity: intensity,
            getPositionKey: getPositionKey,
            onPreviewStart: onPreviewStart,
            onPreviewEnd: onPreviewEnd,
          ),
      ],
    );
  }
}
