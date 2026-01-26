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

/// Get the color for a foreign key type.
/// Delegates to AppColors.getMappingForeignKeyColor for consistency.
Color getForeignKeyColor(String foreignKey, ColorIntensity intensity) {
  return AppColors.getMappingForeignKeyColor(foreignKey, intensity);
}

/// Get color for a field by its position index.
/// Colors are purely position-based for consistency across all entity types.
Color getFieldColor(String fieldKey, int colorIndex, ColorIntensity intensity) {
  return AppColors.getMappingFieldColor(colorIndex, intensity);
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
