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

class AssetSection extends ConsumerStatefulWidget {
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
  ConsumerState<AssetSection> createState() => _AssetSectionState();
}

class _AssetSectionState extends ConsumerState<AssetSection> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand when editing with an existing asset or when pre-filled
    if (widget.formState.assetId != null) {
      _isExpanded = true;
    }
  }

  @override
  void didUpdateWidget(AssetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand when an asset gets auto-suggested or pre-filled
    if (oldWidget.formState.assetId == null && widget.formState.assetId != null) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final globalShowAssets = ref.watch(showAssetSelectorProvider);
    final isTransfer = widget.formState.isTransfer;

    if (isTransfer || !globalShowAssets) return const SizedBox.shrink();

    final activeAssets = ref.watch(activeAssetsProvider);
    if (activeAssets.isEmpty) return const SizedBox.shrink();

    final selectedAsset = widget.formState.assetId != null
        ? ref.watch(assetByIdProvider(widget.formState.assetId!))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsed header / expand toggle
        GestureDetector(
          onTap: () {
            HapticHelper.lightImpact();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selectedAsset != null
                  ? selectedAsset.getColor(intensity).withValues(alpha: AppColors.getBgOpacity(intensity))
                  : AppColors.surface,
              borderRadius: AppRadius.smAll,
              border: Border.all(
                color: selectedAsset != null
                    ? selectedAsset.getColor(intensity)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selectedAsset != null ? selectedAsset.icon : LucideIcons.box,
                  size: 16,
                  color: selectedAsset != null
                      ? selectedAsset.getColor(intensity)
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    selectedAsset != null
                        ? selectedAsset.name
                        : 'Asset (optional)',
                    style: AppTypography.labelSmall.copyWith(
                      color: selectedAsset != null
                          ? selectedAsset.getColor(intensity)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (selectedAsset != null) ...[
                  GestureDetector(
                    onTap: () {
                      HapticHelper.lightImpact();
                      widget.onAssetChanged(null);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                Icon(
                  _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),

        // Auto-suggestion hint
        if (widget.formState.assetAutoSelected && selectedAsset != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Auto-suggested from merchant',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    HapticHelper.lightImpact();
                    widget.onClearAsset();
                  },
                  child: Icon(LucideIcons.x, size: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),

        // Expanded asset selector
        if (_isExpanded) ...[
          const SizedBox(height: AppSpacing.sm),
          Builder(builder: (context) {
            final categoryAssets = ref.watch(assetsForCategoryProvider(widget.formState.categoryId));
            final assetsFoldedCount = ref.watch(assetsFoldedCountProvider);
            final showAddAssetButton = ref.watch(showAddAssetButtonProvider);
            final assetSortOption = ref.watch(assetSortOptionProvider);
            final recentAssetIds = ref.watch(recentlyUsedAssetIdsProvider);

            return AssetSelector(
              assets: activeAssets,
              categoryAssets: categoryAssets,
              selectedId: widget.formState.assetId,
              recentAssetIds: recentAssetIds,
              initialVisibleCount: assetsFoldedCount,
              sortOption: assetSortOption,
              onChanged: widget.onAssetChanged,
              onCreatePressed: showAddAssetButton
                  ? () => widget.onCreateAsset()
                  : null,
            );
          }),
          if (widget.formState.assetId != null &&
              widget.formState.type == TransactionType.expense &&
              widget.onAcquisitionCostChanged != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => widget.onAcquisitionCostChanged!(!widget.formState.isAcquisitionCost),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: widget.formState.isAcquisitionCost
                        ? AppColors.accentPrimary.withValues(alpha: 0.1)
                        : AppColors.surface,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: widget.formState.isAcquisitionCost
                          ? AppColors.accentPrimary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.formState.isAcquisitionCost
                            ? LucideIcons.checkSquare
                            : LucideIcons.square,
                        size: 16,
                        color: widget.formState.isAcquisitionCost
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
                                color: widget.formState.isAcquisitionCost
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
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
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
