import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';

class TransactionsSettingsScreen extends ConsumerWidget {
  const TransactionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Pinned header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
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
                      Text('Transactions', style: AppTypography.h3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Defaults section
                    SettingsSection(
                      title: 'Defaults',
                      children: [
                        _buildDefaultTypeTile(context, ref, settings.defaultTransactionType),
                        SettingsToggleTile(
                          title: 'Select Last Account',
                          description: 'Pre-select last used account',
                          value: settings.selectLastAccount,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setSelectLastAccount(value),
                        ),
                        SettingsToggleTile(
                          title: 'Select Last Category',
                          description: 'Pre-select last used category',
                          value: settings.selectLastCategory,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setSelectLastCategory(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Validation section
                    SettingsSection(
                      title: 'Validation',
                      children: [
                        SettingsToggleTile(
                          title: 'Allow Zero Amount',
                          description: 'Allow saving transactions with \$0',
                          value: settings.allowZeroAmount,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setAllowZeroAmount(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Display section
                    SettingsSection(
                      title: 'Display',
                      children: [
                        _buildAmountSizeTile(context, ref, settings.transactionAmountSize),
                        _buildCategorySortTile(context, ref, settings.categorySortOption),
                        _buildVisibleCategoriesTile(context, ref, settings.categoriesFoldedCount),
                        _buildVisibleAccountsTile(context, ref, settings.accountsFoldedCount),
                        SettingsToggleTile(
                          title: 'Show Add Account Button',
                          description: 'Show "New Account" in form',
                          value: settings.showAddAccountButton,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setShowAddAccountButton(value),
                        ),
                        SettingsToggleTile(
                          title: 'Show Add Category Button',
                          description: 'Show "New" category in form',
                          value: settings.showAddCategoryButton,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setShowAddCategoryButton(value),
                        ),
                        SettingsToggleTile(
                          title: 'Allow Select Parent Category',
                          description: 'Select parent categories directly',
                          value: settings.allowSelectParentCategory,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setAllowSelectParentCategory(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Assets section
                    SettingsSection(
                      title: 'Assets',
                      children: [
                        SettingsToggleTile(
                          title: 'Show Asset Selector',
                          description: 'Show asset section in transaction form',
                          value: settings.showAssetSelector,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setShowAssetSelector(value),
                        ),
                        _buildAssetSortTile(context, ref, settings.assetSortOption),
                        _buildVisibleAssetsTile(context, ref, settings.assetsFoldedCount),
                        SettingsToggleTile(
                          title: 'Show Add Asset Button',
                          description: 'Show "New" asset in form',
                          value: settings.showAddAssetButton,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setShowAddAssetButton(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSizeTile(BuildContext context, WidgetRef ref, AmountDisplaySize currentSize) {
    return SettingsTile(
      title: 'Amount Size',
      description: 'Size of amount field in form',
      value: currentSize.displayName,
      onTap: () => _showAmountSizePicker(context, ref, currentSize),
    );
  }

  void _showAmountSizePicker(BuildContext context, WidgetRef ref, AmountDisplaySize currentSize) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = AmountDisplaySize.values.map((e) => e.displayName).toList();
    final selectedIndex = AmountDisplaySize.values.indexOf(currentSize);
    final modalContent = _OptionPickerSheet(
      title: 'Amount Size',
      options: options,
      selectedIndex: selectedIndex,
      hint: 'Small is better for privacy',
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setTransactionAmountSize(AmountDisplaySize.values[index]);
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  Widget _buildDefaultTypeTile(BuildContext context, WidgetRef ref, TransactionType currentType) {
    final typeLabels = {
      TransactionType.income: 'Income',
      TransactionType.expense: 'Expense',
    };
    return SettingsTile(
      title: 'Default Type',
      description: 'Default transaction type for new entries',
      value: typeLabels[currentType],
      onTap: () => _showDefaultTypePicker(context, ref, currentType),
    );
  }

  void _showDefaultTypePicker(BuildContext context, WidgetRef ref, TransactionType currentType) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = _OptionPickerSheet(
      title: 'Default Type',
      options: const ['Income', 'Expense'],
      selectedIndex: currentType == TransactionType.income ? 0 : 1,
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setDefaultTransactionType(
              index == 0 ? TransactionType.income : TransactionType.expense,
            );
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  Widget _buildCategorySortTile(BuildContext context, WidgetRef ref, CategorySortOption currentOption) {
    return SettingsTile(
      title: 'Category Sort',
      description: 'How to sort categories in form',
      value: currentOption.displayName,
      onTap: () => _showCategorySortPicker(context, ref, currentOption),
    );
  }

  void _showCategorySortPicker(BuildContext context, WidgetRef ref, CategorySortOption currentOption) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = CategorySortOption.values.map((e) => e.displayName).toList();
    final selectedIndex = CategorySortOption.values.indexOf(currentOption);
    final modalContent = _OptionPickerSheet(
      title: 'Category Sort',
      options: options,
      selectedIndex: selectedIndex,
      hint: 'List Order is manually sorted in Settings → Categories',
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setCategorySortOption(CategorySortOption.values[index]);
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  Widget _buildVisibleCategoriesTile(BuildContext context, WidgetRef ref, int currentCount) {
    return SettingsTile(
      title: 'Visible Categories',
      description: 'Categories shown before "More" button',
      value: '$currentCount',
      onTap: () => _showVisibleCategoriesPicker(context, ref, currentCount),
    );
  }

  void _showVisibleCategoriesPicker(BuildContext context, WidgetRef ref, int currentCount) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = ['2', '5', '8', '11', '14', '17', '20', '23'];
    final selectedIndex = options.indexOf('$currentCount');
    final modalContent = _OptionPickerSheet(
      title: 'Visible Categories',
      options: options,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 1, // Default to 5
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setCategoriesFoldedCount(int.parse(options[index]));
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  Widget _buildVisibleAccountsTile(BuildContext context, WidgetRef ref, int currentCount) {
    return SettingsTile(
      title: 'Visible Accounts',
      description: 'Accounts shown before "More" button',
      value: '$currentCount',
      onTap: () => _showVisibleAccountsPicker(context, ref, currentCount),
    );
  }

  Widget _buildAssetSortTile(BuildContext context, WidgetRef ref, AssetSortOption currentOption) {
    return SettingsTile(
      title: 'Asset Sort',
      description: 'How to sort assets in form',
      value: currentOption.displayName,
      onTap: () => _showAssetSortPicker(context, ref, currentOption),
    );
  }

  void _showAssetSortPicker(BuildContext context, WidgetRef ref, AssetSortOption currentOption) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = AssetSortOption.values.map((e) => e.displayName).toList();
    final selectedIndex = AssetSortOption.values.indexOf(currentOption);
    final modalContent = _OptionPickerSheet(
      title: 'Asset Sort',
      options: options,
      selectedIndex: selectedIndex,
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setAssetSortOption(AssetSortOption.values[index]);
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  Widget _buildVisibleAssetsTile(BuildContext context, WidgetRef ref, int currentCount) {
    return SettingsTile(
      title: 'Visible Assets',
      description: 'Assets shown before "More" button',
      value: '$currentCount',
      onTap: () => _showVisibleAssetsPicker(context, ref, currentCount),
    );
  }

  void _showVisibleAssetsPicker(BuildContext context, WidgetRef ref, int currentCount) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = ['2', '5', '8', '11', '14'];
    final selectedIndex = options.indexOf('$currentCount');
    final modalContent = _OptionPickerSheet(
      title: 'Visible Assets',
      options: options,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 1, // Default to 5
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setAssetsFoldedCount(int.parse(options[index]));
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  void _showVisibleAccountsPicker(BuildContext context, WidgetRef ref, int currentCount) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = ['1', '3', '5', '7', '9', '11', '13'];
    final selectedIndex = options.indexOf('$currentCount');
    final modalContent = _OptionPickerSheet(
      title: 'Visible Accounts',
      options: options,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 1, // Default to 3
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setAccountsFoldedCount(int.parse(options[index]));
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }
}

class _OptionPickerSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? hint;

  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.h4),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(options.length, (index) {
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          options[index],
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.check,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
