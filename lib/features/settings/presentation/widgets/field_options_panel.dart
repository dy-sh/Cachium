import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/field_mapping_options.dart';
import '../providers/flexible_csv_import_providers.dart';

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
    final selectedCsvColumn = ref.watch(selectedCsvColumnProvider);
    final accentColor = AppColors.getAccentColor(0, intensity);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 2),
          right: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 2),
          bottom: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 2),
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
                    hasCsvColumnSelected: selectedCsvColumn != null,
                    intensity: intensity,
                    onTap: () {
                      if (config.nameColumn != null) {
                        notifier.clearForeignKeyField(foreignKey, 'name');
                      } else if (selectedCsvColumn != null) {
                        notifier.connectToForeignKeyField(foreignKey, 'name');
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MappableSubField(
                    label: 'ID column',
                    mappedColumn: config.idColumn,
                    hasCsvColumnSelected: selectedCsvColumn != null,
                    intensity: intensity,
                    onTap: () {
                      if (config.idColumn != null) {
                        notifier.clearForeignKeyField(foreignKey, 'id');
                      } else if (selectedCsvColumn != null) {
                        notifier.connectToForeignKeyField(foreignKey, 'id');
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
                color: isSelected ? accentColor : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
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
              color: isSelected ? accentColor : AppColors.textPrimary,
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
  final bool hasCsvColumnSelected;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _MappableSubField({
    required this.label,
    required this.mappedColumn,
    required this.hasCsvColumnSelected,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMapped = mappedColumn != null;
    final canReceiveMapping = hasCsvColumnSelected && !isMapped;
    final accentColor = AppColors.getAccentColor(1, intensity);

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
              : canReceiveMapping
                  ? accentColor.withValues(alpha: 0.05)
                  : AppColors.surface,
          borderRadius: AppRadius.input,
          border: Border.all(
            color: isMapped
                ? accentColor.withValues(alpha: 0.5)
                : canReceiveMapping
                    ? accentColor.withValues(alpha: 0.3)
                    : AppColors.border,
            width: canReceiveMapping ? 2 : 1,
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
                      color: isMapped ? accentColor : AppColors.textSecondary,
                      fontWeight: isMapped ? FontWeight.w600 : FontWeight.w500,
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
              Icon(LucideIcons.x, size: 14, color: accentColor)
            else if (canReceiveMapping)
              Icon(
                LucideIcons.plus,
                size: 14,
                color: accentColor.withValues(alpha: 0.6),
              ),
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
          onTap: () => _showCategoryPicker(context, categories),
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
          onTap: () => _showAccountPicker(context, accounts),
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
    final accentColor = AppColors.getAccentColor(0, intensity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: AppRadius.input,
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? accentColor : AppColors.textSecondary,
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

  void _showCategoryPicker(BuildContext context, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('Select Category', style: AppTypography.h4),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.id == selectedEntityId;
                    return ListTile(
                      leading: Icon(
                        category.icon,
                        color: isSelected
                            ? AppColors.income
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        category.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.income
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(LucideIcons.check, color: AppColors.income)
                          : null,
                      onTap: () {
                        onSelect(category.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountPicker(BuildContext context, List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('Select Account', style: AppTypography.h4),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final isSelected = account.id == selectedEntityId;
                    return ListTile(
                      leading: Icon(
                        account.icon,
                        color: isSelected
                            ? AppColors.income
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        account.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.income
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(LucideIcons.check, color: AppColors.income)
                          : null,
                      onTap: () {
                        onSelect(account.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
