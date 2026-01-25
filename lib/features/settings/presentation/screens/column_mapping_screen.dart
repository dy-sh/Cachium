import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flexible_csv_import_config.dart';
import '../../data/models/import_preset.dart';
import '../providers/flexible_csv_import_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/two_panel_mapping_view.dart';

/// Screen for mapping CSV columns to app fields using a two-panel layout.
class ColumnMappingScreen extends ConsumerWidget {
  const ColumnMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flexibleCsvImportProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final canProceed = ref.watch(canProceedToPreviewProvider);
    final fileName = ref.watch(currentCsvFileNameProvider);
    final progress = ref.watch(mappingProgressProvider);

    if (state.config == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final config = state.config!;
    final fields = ImportFieldDefinitions.getFieldsForType(config.entityType);
    final presets = BuiltInPresets.getPresetsForType(config.entityType);
    final isTransaction = config.entityType == ImportEntityType.transaction;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(
              context,
              ref,
              fileName,
              progress,
              intensity,
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File info and preset row
                    _buildFileInfoAndPresetRow(
                      context,
                      ref,
                      config,
                      presets,
                      state.appliedPreset,
                      intensity,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Category/Account section for transactions
                    if (isTransaction) ...[
                      _buildCategoryAccountSection(
                        context,
                        ref,
                        state,
                        config,
                        intensity,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Two-panel mapping view
                    Expanded(
                      child: TwoPanelMappingView(
                        fields: fields,
                        showForeignKeyFields: !isTransaction,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action
            _buildBottomAction(context, ref, canProceed, state.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String? fileName,
    (int, int) progress,
    ColorIntensity intensity,
  ) {
    final (mapped, total) = progress;
    final accentColor = AppColors.getAccentColor(0, intensity);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  ref
                      .read(flexibleCsvImportProvider.notifier)
                      .goBackToTypeSelection();
                  context.pop();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    LucideIcons.chevronLeft,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Map Columns', style: AppTypography.h3),
                    if (fileName != null)
                      Text(
                        fileName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Progress badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: mapped >= total
                      ? AppColors.income.withValues(alpha: 0.15)
                      : accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$mapped/$total mapped',
                  style: AppTypography.labelSmall.copyWith(
                    color: mapped >= total ? AppColors.income : accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildFileInfoAndPresetRow(
    BuildContext context,
    WidgetRef ref,
    FlexibleCsvImportConfig config,
    List<ImportPreset> presets,
    ImportPreset? appliedPreset,
    ColorIntensity intensity,
  ) {
    final accentColor = AppColors.getAccentColor(0, intensity);

    return Row(
      children: [
        // File info (compact)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.fileSpreadsheet,
                    size: 16,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${config.csvRows.length} rows',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${config.csvHeaders.length} columns',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Preset button (if available)
        if (presets.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          _buildPresetButton(
            context,
            ref,
            presets,
            appliedPreset,
            intensity,
          ),
        ],
      ],
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    WidgetRef ref,
    List<ImportPreset> presets,
    ImportPreset? appliedPreset,
    ColorIntensity intensity,
  ) {
    final accentColor = AppColors.getAccentColor(0, intensity);
    final hasPreset = appliedPreset != null;

    return GestureDetector(
      onTap: () => _showPresetPicker(context, ref, presets, appliedPreset),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: hasPreset
              ? accentColor.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: hasPreset ? accentColor : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasPreset ? LucideIcons.check : LucideIcons.sparkles,
              size: 16,
              color: hasPreset ? accentColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              hasPreset ? appliedPreset.name : 'Preset',
              style: AppTypography.bodySmall.copyWith(
                color: hasPreset ? accentColor : AppColors.textPrimary,
                fontWeight: hasPreset ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetPicker(
    BuildContext context,
    WidgetRef ref,
    List<ImportPreset> presets,
    ImportPreset? appliedPreset,
  ) {
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
                child: Text('Quick Presets', style: AppTypography.h4),
              ),
              const SizedBox(height: AppSpacing.md),
              ...presets.map((preset) {
                final isApplied = appliedPreset?.id == preset.id;
                return ListTile(
                  leading: Icon(
                    isApplied ? LucideIcons.check : LucideIcons.sparkles,
                    color:
                        isApplied ? AppColors.income : AppColors.textSecondary,
                  ),
                  title: Text(
                    preset.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color:
                          isApplied ? AppColors.income : AppColors.textPrimary,
                      fontWeight:
                          isApplied ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: preset.description.isNotEmpty
                      ? Text(
                          preset.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(flexibleCsvImportProvider.notifier)
                        .applyPreset(preset);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryAccountSection(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
    FlexibleCsvImportConfig config,
    ColorIntensity intensity,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY & ACCOUNT',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Row with category and account pickers
          Row(
            children: [
              // Category
              Expanded(
                child: _buildCompactEntityPicker(
                  context: context,
                  ref: ref,
                  label: 'Category',
                  icon: LucideIcons.tag,
                  useSameForAll: state.useSameCategoryForAll,
                  selectedEntityId: state.defaultCategoryId,
                  onUseSameChanged: (value) {
                    ref
                        .read(flexibleCsvImportProvider.notifier)
                        .setUseSameCategoryForAll(value);
                  },
                  buildPicker: () =>
                      _buildCategoryPickerButton(context, ref, state, intensity),
                  intensity: intensity,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Account
              Expanded(
                child: _buildCompactEntityPicker(
                  context: context,
                  ref: ref,
                  label: 'Account',
                  icon: LucideIcons.wallet,
                  useSameForAll: state.useSameAccountForAll,
                  selectedEntityId: state.defaultAccountId,
                  onUseSameChanged: (value) {
                    ref
                        .read(flexibleCsvImportProvider.notifier)
                        .setUseSameAccountForAll(value);
                  },
                  buildPicker: () =>
                      _buildAccountPickerButton(context, ref, state, intensity),
                  intensity: intensity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEntityPicker({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required bool useSameForAll,
    required String? selectedEntityId,
    required ValueChanged<bool> onUseSameChanged,
    required Widget Function() buildPicker,
    required ColorIntensity intensity,
  }) {
    final accentColor = AppColors.getAccentColor(0, intensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle row
        GestureDetector(
          onTap: () => onUseSameChanged(!useSameForAll),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color:
                      useSameForAll ? accentColor : AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: useSameForAll ? accentColor : AppColors.border,
                  ),
                ),
                child: useSameForAll
                    ? Icon(LucideIcons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color:
                      useSameForAll ? accentColor : AppColors.textSecondary,
                  fontWeight:
                      useSameForAll ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        // Picker (if enabled)
        if (useSameForAll) ...[
          const SizedBox(height: AppSpacing.xs),
          buildPicker(),
        ],
      ],
    );
  }

  Widget _buildCategoryPickerButton(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
    ColorIntensity intensity,
  ) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final selectedCategory = state.defaultCategoryId != null
            ? categories
                .where((c) => c.id == state.defaultCategoryId)
                .firstOrNull
            : null;

        return GestureDetector(
          onTap: () => _showCategoryPicker(
              context, ref, categories, state.defaultCategoryId),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.input,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  selectedCategory?.icon ?? LucideIcons.tag,
                  size: 14,
                  color: selectedCategory != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedCategory?.name ?? 'Select...',
                    style: AppTypography.labelSmall.copyWith(
                      color: selectedCategory != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 28,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Text('Error', style: AppTypography.labelSmall),
    );
  }

  Widget _buildAccountPickerButton(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
    ColorIntensity intensity,
  ) {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        final selectedAccount = state.defaultAccountId != null
            ? accounts.where((a) => a.id == state.defaultAccountId).firstOrNull
            : null;

        return GestureDetector(
          onTap: () => _showAccountPicker(
              context, ref, accounts, state.defaultAccountId),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.input,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  selectedAccount?.icon ?? LucideIcons.wallet,
                  size: 14,
                  color: selectedAccount != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedAccount?.name ?? 'Select...',
                    style: AppTypography.labelSmall.copyWith(
                      color: selectedAccount != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 28,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Text('Error', style: AppTypography.labelSmall),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
    String? selectedId,
  ) {
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
                    final isSelected = category.id == selectedId;
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
                        ref
                            .read(flexibleCsvImportProvider.notifier)
                            .setDefaultCategory(category.id);
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

  void _showAccountPicker(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
    String? selectedId,
  ) {
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
                    final isSelected = account.id == selectedId;
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
                        ref
                            .read(flexibleCsvImportProvider.notifier)
                            .setDefaultAccount(account.id);
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

  Widget _buildBottomAction(
    BuildContext context,
    WidgetRef ref,
    bool canProceed,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: 'Preview Import',
          onPressed: canProceed && !isLoading
              ? () async {
                  final success = await ref
                      .read(flexibleCsvImportProvider.notifier)
                      .generatePreview();
                  if (success && context.mounted) {
                    context.push(AppRoutes.csvImportPreview);
                  } else if (!success && context.mounted) {
                    final error = ref.read(flexibleCsvImportProvider).error;
                    if (error != null) {
                      context.showErrorNotification(error);
                    }
                  }
                }
              : null,
          isLoading: isLoading,
        ),
      ),
    );
  }
}
