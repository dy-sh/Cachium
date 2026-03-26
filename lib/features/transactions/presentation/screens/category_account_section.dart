import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../assets/presentation/widgets/asset_selector.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_selector.dart';

class CategorySection extends ConsumerWidget {
  final TransactionFormState formState;
  final ValueChanged<String?> onCategoryChanged;
  final void Function(String? parentId) onCreateCategory;

  const CategorySection({
    super.key,
    required this.formState,
    required this.onCategoryChanged,
    required this.onCreateCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final categoriesFoldedCount = ref.watch(categoriesFoldedCountProvider);
    final showAddCategoryButton = ref.watch(showAddCategoryButtonProvider);
    final categorySortOption = ref.watch(categorySortOptionProvider);
    final allowSelectParentCategory = ref.watch(allowSelectParentCategoryProvider);

    final categories = formState.type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    final categoryType = formState.type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final recentCategoryIds = ref.watch(recentlyUsedCategoryIdsProvider(categoryType));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: AppTypography.labelMedium),
        if (formState.categoryError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              formState.categoryError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        CategorySelector(
          categories: categories,
          selectedId: formState.categoryId,
          initialVisibleCount: categoriesFoldedCount,
          sortOption: categorySortOption,
          recentCategoryIds: recentCategoryIds,
          allowSelectParentCategory: allowSelectParentCategory,
          onChanged: onCategoryChanged,
          onCreatePressed: showAddCategoryButton
              ? (parentId) => onCreateCategory(parentId)
              : null,
        ),
      ],
    );
  }
}

class AssetSection extends ConsumerWidget {
  final TransactionFormState formState;
  final ValueChanged<String?> onAssetChanged;
  final VoidCallback onCreateAsset;
  final VoidCallback onClearAsset;
  final ValueChanged<bool>? onAcquisitionCostChanged;

  const AssetSection({
    super.key,
    required this.formState,
    required this.onAssetChanged,
    required this.onCreateAsset,
    required this.onClearAsset,
    this.onAcquisitionCostChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final globalShowAssets = ref.watch(showAssetSelectorProvider);
    final categoryShowsAssets = ref.watch(categoryShowsAssetsProvider(formState.categoryId));
    final isTransfer = formState.isTransfer;
    final showAssets = !isTransfer && globalShowAssets && (categoryShowsAssets || formState.assetId != null);

    // Auto-clear asset when category changes to one that doesn't show assets
    // (skip for editing mode and when asset was pre-selected before category choice)
    if (!isTransfer && globalShowAssets && !categoryShowsAssets &&
        formState.assetId != null && !formState.isEditing &&
        formState.categoryId != null) {
      Future.microtask(() {
        onClearAsset();
      });
    }

    if (showAssets) {
      final activeAssets = ref.watch(activeAssetsProvider);
      final categoryAssets = ref.watch(assetsForCategoryProvider(formState.categoryId));
      final assetsFoldedCount = ref.watch(assetsFoldedCountProvider);
      final showAddAssetButton = ref.watch(showAddAssetButtonProvider);
      final assetSortOption = ref.watch(assetSortOptionProvider);
      final recentAssetIds = ref.watch(recentlyUsedAssetIdsProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asset (optional)', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          AssetSelector(
            assets: activeAssets,
            categoryAssets: categoryAssets,
            selectedId: formState.assetId,
            recentAssetIds: recentAssetIds,
            initialVisibleCount: assetsFoldedCount,
            sortOption: assetSortOption,
            onChanged: onAssetChanged,
            onCreatePressed: showAddAssetButton
                ? () => onCreateAsset()
                : null,
          ),
          if (formState.assetId != null &&
              formState.type == TransactionType.expense &&
              onAcquisitionCostChanged != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onAcquisitionCostChanged!(!formState.isAcquisitionCost),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: formState.isAcquisitionCost
                        ? AppColors.accentPrimary.withValues(alpha: 0.1)
                        : AppColors.surface,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: formState.isAcquisitionCost
                          ? AppColors.accentPrimary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        formState.isAcquisitionCost
                            ? LucideIcons.checkSquare
                            : LucideIcons.square,
                        size: 16,
                        color: formState.isAcquisitionCost
                            ? AppColors.accentPrimary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acquisition cost',
                              style: AppTypography.labelSmall.copyWith(
                                color: formState.isAcquisitionCost
                                    ? AppColors.accentPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Part of the purchase price of this asset',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      );
    }

    // Show linked asset read-only when editing a tx that has an asset
    // but the category now has showAssets=false
    if (!isTransfer && globalShowAssets && formState.assetId != null && formState.isEditing) {
      final asset = ref.watch(assetByIdProvider(formState.assetId!));
      if (asset == null) return const SizedBox.shrink();
      final assetColor = asset.getColor(intensity);
      final bgOpacity = AppColors.getBgOpacity(intensity);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asset', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: assetColor.withValues(alpha: bgOpacity),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: assetColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(asset.icon, size: 14, color: assetColor),
                    const SizedBox(width: 4),
                    Text(
                      asset.name,
                      style: AppTypography.labelSmall.copyWith(color: assetColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () {
                  HapticHelper.lightImpact();
                  onAssetChanged(null);
                },
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class AccountSection extends ConsumerWidget {
  final TransactionFormState formState;
  final ValueChanged<String?> onAccountChanged;
  final VoidCallback onCreateAccount;

  const AccountSection({
    super.key,
    required this.formState,
    required this.onAccountChanged,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrEmpty;
    final recentAccountIds = ref.watch(recentlyUsedAccountIdsProvider);
    final accountsFoldedCount = ref.watch(accountsFoldedCountProvider);
    final showAddAccountButton = ref.watch(showAddAccountButtonProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formState.isTransfer ? 'From Account' : 'Account', style: AppTypography.labelMedium),
        if (formState.accountError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              formState.accountError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        AccountSelector(
          accounts: accounts,
          selectedId: formState.accountId,
          recentAccountIds: recentAccountIds,
          initialVisibleCount: accountsFoldedCount,
          excludeAccountId: formState.isTransfer ? formState.destinationAccountId : null,
          onChanged: onAccountChanged,
          onCreatePressed: showAddAccountButton
              ? () => onCreateAccount()
              : null,
        ),
      ],
    );
  }
}
