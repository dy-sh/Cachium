import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/field_mapping_options.dart';
import '../providers/flexible_csv_import_providers.dart';
import 'field_options_panel.dart';

/// Color index for Category FK field (cyan - index 13).
const int categoryColorIndex = 13;
/// Color index for Account FK field (orange - index 3).
const int accountColorIndex = 3;

/// Get the color for a foreign key type.
Color getForeignKeyColor(String foreignKey, ColorIntensity intensity) {
  final colorIndex = foreignKey == 'category' ? categoryColorIndex : accountColorIndex;
  return AppColors.getAccentColor(colorIndex, intensity);
}

/// Get a distinct color for regular field badges.
/// New 24-color palette indices (15° spacing on color wheel):
///   0: white, 1: red, 2: vermilion, 3: orange*, 4: amber, 5: yellow, 6: chartreuse,
///   7: lime, 8: harlequin, 9: green*, 10: emerald, 11: jade, 12: aquamarine,
///   13: cyan*, 14: sky, 15: azure, 16: cerulean, 17: blue, 18: indigo,
///   19: violet, 20: purple, 21: magenta, 22: fuchsia, 23: rose
/// (* = reserved: cyan for Category, orange for Account, green for Amount)
Color getFieldBadgeColor(int badgeNumber, ColorIntensity intensity) {
  // Pick distinct colors avoiding: cyan(13), orange(3), green(9), blue tones, yellow tones, red tones
  // Using: violet(19), magenta(21), purple(20), fuchsia(22), emerald(10), jade(11), aquamarine(12), lime(7), rose(23), harlequin(8)
  const distinctIndices = [19, 21, 20, 22, 10, 11, 12, 7, 23, 8];
  final index = distinctIndices[(badgeNumber - 1) % distinctIndices.length];
  return AppColors.getAccentColor(index, intensity);
}

/// Get a semantically meaningful icon for a field based on its key.
/// Returns icons that represent the field's purpose.
IconData getFieldIconByKey(String fieldKey) {
  final key = fieldKey.toLowerCase();

  // Date/time fields
  if (key.contains('date') || key.contains('time') ||
      key.contains('created') || key.contains('updated')) {
    return LucideIcons.calendar;
  }

  // Amount/money fields
  if (key.contains('amount') || key.contains('balance') ||
      key.contains('value') || key.contains('price') || key.contains('cost')) {
    return LucideIcons.coins;
  }

  // Description/text fields
  if (key.contains('description') || key.contains('notes') ||
      key.contains('memo') || key.contains('comment')) {
    return LucideIcons.fileText;
  }

  // Name/title fields
  if (key.contains('name') || key.contains('title') || key.contains('label')) {
    return LucideIcons.type;
  }

  // Type fields
  if (key.contains('type') || key.contains('kind')) {
    return LucideIcons.listTree;
  }

  // Category fields
  if (key.contains('category')) {
    return LucideIcons.tag;
  }

  // Account fields
  if (key.contains('account')) {
    return LucideIcons.wallet;
  }

  // Icon fields
  if (key.contains('icon') || key.contains('image')) {
    return LucideIcons.image;
  }

  // Color fields
  if (key.contains('color') || key.contains('colour')) {
    return LucideIcons.palette;
  }

  // ID fields
  if (key == 'id' || key.endsWith('id') || key.endsWith('_id')) {
    return LucideIcons.hash;
  }

  // Parent/hierarchy fields
  if (key.contains('parent')) {
    return LucideIcons.gitBranch;
  }

  // Currency fields
  if (key.contains('currency')) {
    return LucideIcons.dollarSign;
  }

  // Status fields
  if (key.contains('status') || key.contains('state')) {
    return LucideIcons.toggleLeft;
  }

  // Default fallback
  return LucideIcons.circleDot;
}

/// An expandable item for foreign key fields (Category/Account).
/// Shows a summary when collapsed, expands to show mapping options.
class ExpandableForeignKeyItem extends ConsumerWidget {
  final String foreignKey; // 'category' or 'account'
  final String displayName;
  final IconData icon;
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

  const ExpandableForeignKeyItem({
    super.key,
    required this.foreignKey,
    required this.displayName,
    required this.icon,
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
    final config = foreignKey == 'category'
        ? ref.watch(categoryConfigProvider)
        : ref.watch(accountConfigProvider);

    final accentColor = getForeignKeyColor(foreignKey, intensity);
    final isConfigured = config.isValid;
    // Dim configured items when selecting another field (but not if highlighted)
    final isDimmed = hasCsvColumnSelected && !isExpanded && !isHighlighted;
    // Show as active when configured or highlighted
    final showActive = isConfigured || isHighlighted;

    // Get summary text
    final summary = _getSummary(ref, config);

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
                    color: showActive
                        ? accentColor
                        : AppColors.textTertiary,
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
                              displayName,
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
                        if (!isExpanded && summary != null)
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
                    icon,
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
          ForeignKeyOptionsPanel(
            foreignKey: foreignKey,
            intensity: intensity,
            getPositionKey: getPositionKey,
            onPreviewStart: onPreviewStart,
            onPreviewEnd: onPreviewEnd,
          ),
      ],
    );
  }

  String? _getSummary(WidgetRef ref, ForeignKeyConfig config) {
    switch (config.mode) {
      case ForeignKeyResolutionMode.mapFromCsv:
        if (config.nameColumn != null && config.idColumn != null) {
          return '"${config.nameColumn}" + "${config.idColumn}"';
        } else if (config.nameColumn != null) {
          return '"${config.nameColumn}"';
        } else if (config.idColumn != null) {
          return '"${config.idColumn}"';
        }
        return 'Select field...';

      case ForeignKeyResolutionMode.useSameForAll:
        if (config.selectedEntityId != null) {
          final name = _getEntityName(ref, config.selectedEntityId!);
          if (name != null) return name;
        }
        return 'Select ${foreignKey == 'category' ? 'category' : 'account'}...';
    }
  }

  String? _getEntityName(WidgetRef ref, String entityId) {
    if (foreignKey == 'category') {
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      final cat = categories.where((c) => c.id == entityId).firstOrNull;
      return cat?.name;
    } else if (foreignKey == 'account') {
      final accounts = ref.read(accountsProvider).valueOrNull ?? [];
      final acc = accounts.where((a) => a.id == entityId).firstOrNull;
      return acc?.name;
    }
    return null;
  }
}
