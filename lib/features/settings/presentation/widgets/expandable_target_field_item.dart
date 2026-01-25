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

/// An expandable item for foreign key fields (Category/Account).
/// Shows a summary when collapsed, expands to show mapping options.
class ExpandableForeignKeyItem extends ConsumerWidget {
  final String foreignKey; // 'category' or 'account'
  final String displayName;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ColorIntensity intensity;

  const ExpandableForeignKeyItem({
    super.key,
    required this.foreignKey,
    required this.displayName,
    required this.icon,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = foreignKey == 'category'
        ? ref.watch(categoryConfigProvider)
        : ref.watch(accountConfigProvider);

    final accentColor = AppColors.getAccentColor(0, intensity);
    final isConfigured = config.isValid;

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
              color: isExpanded
                  ? accentColor.withValues(alpha: 0.12)
                  : isConfigured
                      ? accentColor.withValues(alpha: 0.08)
                      : AppColors.surface,
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : AppRadius.card,
              border: Border.all(
                color: isExpanded
                    ? accentColor.withValues(alpha: 0.5)
                    : isConfigured
                        ? accentColor.withValues(alpha: 0.4)
                        : AppColors.border,
                width: isExpanded ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Icon(
                  icon,
                  size: 18,
                  color: isConfigured ? accentColor : AppColors.textSecondary,
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
                              fontWeight: isConfigured
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isConfigured
                                  ? accentColor
                                  : AppColors.textPrimary,
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
                            color: isConfigured
                                ? accentColor.withValues(alpha: 0.8)
                                : AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Expand/collapse icon
                Icon(
                  isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: isExpanded ? accentColor : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),

        // Expanded options panel
        if (isExpanded)
          ForeignKeyOptionsPanel(
            foreignKey: foreignKey,
            intensity: intensity,
          ),
      ],
    );
  }

  String? _getSummary(WidgetRef ref, ForeignKeyConfig config) {
    switch (config.mode) {
      case ForeignKeyResolutionMode.mapFromCsv:
        if (config.nameColumn != null && config.idColumn != null) {
          return 'Mapping "${config.nameColumn}" + "${config.idColumn}"';
        } else if (config.nameColumn != null) {
          return 'Mapping "${config.nameColumn}"';
        } else if (config.idColumn != null) {
          return 'Mapping "${config.idColumn}"';
        }
        return 'Select column to map';

      case ForeignKeyResolutionMode.useSameForAll:
        if (config.selectedEntityId != null) {
          final name = _getEntityName(ref, config.selectedEntityId!);
          if (name != null) return 'Using: $name';
        }
        return 'Select ${foreignKey == 'category' ? 'category' : 'account'}';
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
