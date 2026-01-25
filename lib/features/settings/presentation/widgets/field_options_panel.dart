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
import 'account_picker_modal.dart';
import 'category_picker_modal.dart';
import 'expandable_target_field_item.dart';

/// Panel for configuring a foreign key (Category or Account).
/// Shows mode selection and either column mapping or entity picker.
class ForeignKeyOptionsPanel extends ConsumerWidget {
  final String foreignKey; // 'category' or 'account'
  final ColorIntensity intensity;

  const ForeignKeyOptionsPanel({
    super.key,
    required this.foreignKey,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    final config = foreignKey == 'category'
        ? ref.watch(categoryConfigProvider)
        : ref.watch(accountConfigProvider);
    final selectedFieldKey = ref.watch(selectedFieldKeyProvider);
    final accentColor = getForeignKeyColor(foreignKey, intensity);

    // Check if this FK's sub-fields are selected
    final isNameSelected = selectedFieldKey == 'fk:$foreignKey:name';
    final isIdSelected = selectedFieldKey == 'fk:$foreignKey:id';
    final isConfigured = config.isValid;
    final borderColor = isConfigured
        ? accentColor.withValues(alpha: 0.4)
        : AppColors.textTertiary.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode: Map from CSV
          _buildModeOption(
            context: context,
            label: 'Map from CSV',
            isSelected: config.mode == ForeignKeyResolutionMode.mapFromCsv,
            accentColor: accentColor,
            onTap: () => notifier.setForeignKeyMode(
              foreignKey,
              ForeignKeyResolutionMode.mapFromCsv,
            ),
          ),

          // Sub-fields for mapping (when Map from CSV is selected)
          if (config.mode == ForeignKeyResolutionMode.mapFromCsv) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                children: [
                  _MappableSubField(
                    label: 'Name column',
                    mappedColumn: config.nameColumn,
                    isSelected: isNameSelected,
                    intensity: intensity,
                    foreignKey: foreignKey,
                    onTap: () {
                      if (config.nameColumn != null) {
                        notifier.clearForeignKeyField(foreignKey, 'name');
                      } else if (isNameSelected) {
                        notifier.selectField(null); // Deselect
                      } else {
                        notifier.selectForeignKeyField(foreignKey, 'name');
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MappableSubField(
                    label: 'ID column',
                    mappedColumn: config.idColumn,
                    isSelected: isIdSelected,
                    intensity: intensity,
                    foreignKey: foreignKey,
                    onTap: () {
                      if (config.idColumn != null) {
                        notifier.clearForeignKeyField(foreignKey, 'id');
                      } else if (isIdSelected) {
                        notifier.selectField(null); // Deselect
                      } else {
                        notifier.selectForeignKeyField(foreignKey, 'id');
                      }
                    },
                  ),
                  if (config.nameColumn == null && config.idColumn == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Select at least one column',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Mode: Use Same for All
          _buildModeOption(
            context: context,
            label: 'Use Same for All',
            isSelected: config.mode == ForeignKeyResolutionMode.useSameForAll,
            accentColor: accentColor,
            onTap: () => notifier.setForeignKeyMode(
              foreignKey,
              ForeignKeyResolutionMode.useSameForAll,
            ),
          ),

          // Entity picker (when Use Same for All is selected)
          if (config.mode == ForeignKeyResolutionMode.useSameForAll) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: _EntityPickerButton(
                foreignKey: foreignKey,
                selectedEntityId: config.selectedEntityId,
                intensity: intensity,
                onSelect: (id) => notifier.setForeignKeyEntity(foreignKey, id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textSecondary : AppColors.textTertiary,
                width: 1,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.textSecondary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A sub-field that can be mapped to a CSV column (like a mini target field).
class _MappableSubField extends StatelessWidget {
  final String label;
  final String? mappedColumn;
  final bool isSelected;
  final ColorIntensity intensity;
  final String foreignKey;
  final VoidCallback onTap;

  const _MappableSubField({
    required this.label,
    required this.mappedColumn,
    required this.isSelected,
    required this.intensity,
    required this.foreignKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMapped = mappedColumn != null;
    final accentColor = getForeignKeyColor(foreignKey, intensity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isMapped
              ? accentColor.withValues(alpha: 0.1)
              : isSelected
                  ? accentColor.withValues(alpha: 0.08)
                  : AppColors.surface,
          borderRadius: AppRadius.input,
          border: Border.all(
            color: isMapped
                ? accentColor.withValues(alpha: 0.5)
                : isSelected
                    ? accentColor.withValues(alpha: 0.6)
                    : AppColors.textTertiary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isMapped || isSelected ? accentColor : AppColors.textSecondary,
                      fontWeight: isMapped || isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (isMapped)
                    Text(
                      '"$mappedColumn"',
                      style: AppTypography.labelSmall.copyWith(
                        color: accentColor,
                      ),
                    ),
                ],
              ),
            ),
            if (isMapped)
              Icon(LucideIcons.x, size: 14, color: accentColor),
          ],
        ),
      ),
    );
  }
}

class _EntityPickerButton extends ConsumerWidget {
  final String foreignKey;
  final String? selectedEntityId;
  final ColorIntensity intensity;
  final ValueChanged<String?> onSelect;

  const _EntityPickerButton({
    required this.foreignKey,
    required this.selectedEntityId,
    required this.intensity,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (foreignKey == 'category') {
      return _buildCategoryPicker(context, ref);
    } else {
      return _buildAccountPicker(context, ref);
    }
  }

  Widget _buildCategoryPicker(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final selected = selectedEntityId != null
            ? categories.where((c) => c.id == selectedEntityId).firstOrNull
            : null;

        return _buildPickerButton(
          context: context,
          icon: selected?.icon ?? LucideIcons.tag,
          label: selected?.name ?? 'Select Category...',
          isSelected: selected != null,
          onTap: () => showCategoryPickerModal(
            context: context,
            selectedCategoryId: selectedEntityId,
            onSelected: (id) => onSelect(id),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Text('Error', style: AppTypography.labelSmall),
    );
  }

  Widget _buildAccountPicker(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        final selected = selectedEntityId != null
            ? accounts.where((a) => a.id == selectedEntityId).firstOrNull
            : null;

        return _buildPickerButton(
          context: context,
          icon: selected?.icon ?? LucideIcons.wallet,
          label: selected?.name ?? 'Select Account...',
          isSelected: selected != null,
          onTap: () => showAccountPickerModal(
            context: context,
            selectedAccountId: selectedEntityId,
            onSelected: (id) => onSelect(id),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Text('Error', style: AppTypography.labelSmall),
    );
  }

  Widget _buildPickerButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textSecondary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: AppRadius.input,
          border: Border.all(
            color: isSelected
                ? AppColors.textSecondary
                : AppColors.textTertiary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
