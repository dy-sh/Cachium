import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';

class HomeSettingsScreen extends ConsumerWidget {
  const HomeSettingsScreen({super.key});

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
                      Text('Home Page', style: AppTypography.h3),
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
                    // Visibility section
                    SettingsSection(
                      title: 'Visibility',
                      children: [
                        SettingsToggleTile(
                          title: 'Show Accounts List',
                          description: 'Display account cards on home',
                          value: settings.homeShowAccountsList,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setHomeShowAccountsList(value),
                        ),
                        SettingsToggleTile(
                          title: 'Show Total Balance',
                          description: 'Display total balance card',
                          value: settings.homeShowTotalBalance,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setHomeShowTotalBalance(value),
                        ),
                        SettingsToggleTile(
                          title: 'Show Quick Actions',
                          description: 'Display income/expense buttons',
                          value: settings.homeShowQuickActions,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setHomeShowQuickActions(value),
                        ),
                        SettingsToggleTile(
                          title: 'Show Recent Transactions',
                          description: 'Display recent transactions list',
                          value: settings.homeShowRecentTransactions,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).setHomeShowRecentTransactions(value),
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
