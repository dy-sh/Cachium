import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../accounts/data/models/account.dart';
import '../../../categories/data/models/category.dart';
import '../../data/models/flexible_csv_import_config.dart';
import '../providers/settings_provider.dart';

/// Widget for configuring foreign key resolution strategy.
class ForeignKeyResolver extends ConsumerWidget {
  final String fieldKey;
  final String entityType; // 'category' or 'account'
  final ForeignKeyMatchStrategy? currentStrategy;
  final String? defaultEntityId;
  final List<Category> availableCategories;
  final List<Account> availableAccounts;
  final ValueChanged<ForeignKeyMatchStrategy> onStrategyChanged;
  final ValueChanged<String?> onDefaultEntityChanged;

  const ForeignKeyResolver({
    super.key,
    required this.fieldKey,
    required this.entityType,
    required this.currentStrategy,
    this.defaultEntityId,
    this.availableCategories = const [],
    this.availableAccounts = const [],
    required this.onStrategyChanged,
    required this.onDefaultEntityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColor = AppColors.getAccentColor(0, intensity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    entityType == 'category'
                        ? LucideIcons.tag
                        : LucideIcons.wallet,
                    size: 16,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entityType == 'category'
                            ? 'Category Resolution'
                            : 'Account Resolution',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'How to match CSV values to existing ${entityType}s',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.border, height: 1),

          // Strategy options
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Match Strategy',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._buildStrategyOptions(accentColor),
              ],
            ),
          ),

          // Default entity picker (when using useDefault strategy)
          if (currentStrategy == ForeignKeyMatchStrategy.useDefault) ...[
            Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default ${entityType == 'category' ? 'Category' : 'Account'}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildEntityPicker(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStrategyOptions(Color accentColor) {
    final strategies = [
      (
        ForeignKeyMatchStrategy.byName,
        LucideIcons.search,
      ),
      (
        ForeignKeyMatchStrategy.byId,
        LucideIcons.hash,
      ),
      (
        ForeignKeyMatchStrategy.useDefault,
        LucideIcons.anchor,
      ),
    ];

    return strategies.map((s) {
      final (strategy, icon) = s;
      final isSelected = currentStrategy == strategy;

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: GestureDetector(
          onTap: () => onStrategyChanged(strategy),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accentColor : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? accentColor : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strategy.displayName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? accentColor
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        strategy.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(LucideIcons.check, size: 18, color: accentColor),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEntityPicker() {
    if (entityType == 'category') {
      return _buildCategoryPicker();
    } else {
      return _buildAccountPicker();
    }
  }

  Widget _buildCategoryPicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.input,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: defaultEntityId,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 18),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          dropdownColor: AppColors.surface,
          borderRadius: AppRadius.card,
          hint: Text(
            'Select a category',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          items: availableCategories.map((cat) {
            return DropdownMenuItem<String?>(
              value: cat.id,
              child: Row(
                children: [
                  Icon(cat.icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: AppTypography.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onDefaultEntityChanged,
        ),
      ),
    );
  }

  Widget _buildAccountPicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.input,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: defaultEntityId,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 18),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          dropdownColor: AppColors.surface,
          borderRadius: AppRadius.card,
          hint: Text(
            'Select an account',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          items: availableAccounts.map((acc) {
            return DropdownMenuItem<String?>(
              value: acc.id,
              child: Row(
                children: [
                  Icon(acc.icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      acc.name,
                      style: AppTypography.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onDefaultEntityChanged,
        ),
      ),
    );
  }
}
