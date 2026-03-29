import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';

class HomeSettingsScreen extends ConsumerWidget {
  const HomeSettingsScreen({super.key});

  static const _sectionLabels = {
    'accounts': 'Accounts List',
    'totalBalance': 'Total Balance',
    'quickActions': 'Quick Actions',
    'budgetProgress': 'Budget Progress',
    'recentTransactions': 'Recent Transactions',
  };

  static const _sectionIcons = {
    'accounts': LucideIcons.creditCard,
    'totalBalance': LucideIcons.wallet,
    'quickActions': LucideIcons.zap,
    'budgetProgress': LucideIcons.pieChart,
    'recentTransactions': LucideIcons.list,
  };

  bool _isSectionVisible(AppSettings settings, String sectionId) {
    switch (sectionId) {
      case 'accounts':
        return settings.homeShowAccountsList;
      case 'totalBalance':
        return settings.homeShowTotalBalance;
      case 'quickActions':
        return settings.homeShowQuickActions;
      case 'budgetProgress':
        return settings.homeShowBudgetProgress;
      case 'recentTransactions':
        return settings.homeShowRecentTransactions;
      default:
        return true;
    }
  }

  void _toggleSectionVisibility(WidgetRef ref, String sectionId, bool value) {
    switch (sectionId) {
      case 'accounts':
        ref.read(settingsProvider.notifier).setHomeShowAccountsList(value);
      case 'totalBalance':
        ref.read(settingsProvider.notifier).setHomeShowTotalBalance(value);
      case 'quickActions':
        ref.read(settingsProvider.notifier).setHomeShowQuickActions(value);
      case 'budgetProgress':
        ref.read(settingsProvider.notifier).setHomeShowBudgetProgress(value);
      case 'recentTransactions':
        ref.read(settingsProvider.notifier).setHomeShowRecentTransactions(value);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: LoadingIndicator()),
      );
    }

    final sectionOrder = settings.homeSectionOrder;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SettingsHeader(title: 'Home Page'),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section order & visibility
                    SettingsSection(
                      title: 'Sections',
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            'Drag to reorder, toggle to show/hide',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              color: Colors.transparent,
                              elevation: 2,
                              shadowColor: Colors.black26,
                              borderRadius: AppRadius.mdAll,
                              child: child,
                            );
                          },
                          itemCount: sectionOrder.length,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;
                            final newOrder = List<String>.from(sectionOrder);
                            final item = newOrder.removeAt(oldIndex);
                            newOrder.insert(newIndex, item);
                            ref.read(settingsProvider.notifier).setHomeSectionOrder(newOrder);
                          },
                          itemBuilder: (context, index) {
                            final sectionId = sectionOrder[index];
                            final isVisible = _isSectionVisible(settings, sectionId);
                            return Container(
                              key: ValueKey(sectionId),
                              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: AppRadius.mdAll,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Icon(
                                      LucideIcons.gripVertical,
                                      size: 18,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(
                                    _sectionIcons[sectionId] ?? LucideIcons.layoutGrid,
                                    size: 18,
                                    color: isVisible ? AppColors.textPrimary : AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _sectionLabels[sectionId] ?? sectionId,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isVisible ? AppColors.textPrimary : AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 24,
                                    width: 44,
                                    child: Switch.adaptive(
                                      value: isVisible,
                                      onChanged: (value) => _toggleSectionVisibility(ref, sectionId, value),
                                      activeTrackColor: ref.watch(accentColorProvider),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Privacy section
                    SettingsSection(
                      title: 'Privacy',
                      children: [
                        _buildAccountsTextSizeTile(context, ref, settings.homeAccountsTextSize),
                        _buildTotalBalanceTextSizeTile(context, ref, settings.homeTotalBalanceTextSize),
                        SettingsToggleTile(
                          title: 'Hide Balances by Default',
                          description: 'Tap to reveal balances on home',
                          value: settings.homeBalancesHiddenByDefault,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setHomeBalancesHiddenByDefault(value),
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

  Widget _buildAccountsTextSizeTile(BuildContext context, WidgetRef ref, AmountDisplaySize currentSize) {
    return SettingsTile(
      title: 'Accounts Text Size',
      description: 'Size of balance text in account cards',
      value: currentSize.displayName,
      onTap: () => _showAccountsTextSizePicker(context, ref, currentSize),
    );
  }

  void _showAccountsTextSizePicker(BuildContext context, WidgetRef ref, AmountDisplaySize currentSize) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = AmountDisplaySize.values.map((e) => e.displayName).toList();
    final selectedIndex = AmountDisplaySize.values.indexOf(currentSize);
    final modalContent = _OptionPickerSheet(
      title: 'Accounts Text Size',
      options: options,
      selectedIndex: selectedIndex,
      hint: 'Small is better for privacy',
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setHomeAccountsTextSize(AmountDisplaySize.values[index]);
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

  Widget _buildTotalBalanceTextSizeTile(BuildContext context, WidgetRef ref, AmountDisplaySize currentSize) {
    return SettingsTile(
      title: 'Total Balance Text Size',
      description: 'Size of total balance amount',
      value: currentSize.displayName,
      onTap: () => _showTotalBalanceTextSizePicker(context, ref, currentSize),
    );
  }

  void _showTotalBalanceTextSizePicker(BuildContext context, WidgetRef ref, AmountDisplaySize currentSize) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = AmountDisplaySize.values.map((e) => e.displayName).toList();
    final selectedIndex = AmountDisplaySize.values.indexOf(currentSize);
    final modalContent = _OptionPickerSheet(
      title: 'Total Balance Text Size',
      options: options,
      selectedIndex: selectedIndex,
      hint: 'Small is better for privacy',
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setHomeTotalBalanceTextSize(AmountDisplaySize.values[index]);
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
                  borderRadius: AppRadius.xxsAll,
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
