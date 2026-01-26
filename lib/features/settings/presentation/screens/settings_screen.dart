import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/reset_settings_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleResetSettings(BuildContext context, WidgetRef ref) async {
    final confirmed = await showResetSettingsDialog(context: context);
    if (confirmed == true && context.mounted) {
      await ref.read(settingsProvider.notifier).resetSettingsSection();
      if (context.mounted) {
        context.showSuccessNotification('Settings reset to defaults');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrEmpty;
    final customCategoryCount = categories.where((c) => c.isCustom).length;
    final intensity = ref.watch(colorIntensityProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text('Settings', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Data Section
                StaggeredListItem(
                  index: 0,
                  child: SettingsSection(
                    title: 'Data',
                    children: [
                      SettingsTile(
                        title: 'Categories',
                        description: customCategoryCount > 0
                            ? '$customCategoryCount custom ${customCategoryCount == 1 ? 'category' : 'categories'}'
                            : 'Manage transaction categories',
                        icon: LucideIcons.tags,
                        iconColor: AppColors.getAccentColor(1, intensity), // Cyan
                        onTap: () => context.push('/settings/categories'),
                      ),
                      SettingsTile(
                        title: 'Database',
                        description: 'Export, import, manage data',
                        icon: LucideIcons.database,
                        iconColor: AppColors.getAccentColor(3, intensity), // Blue
                        onTap: () => context.push('/settings/database'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Settings Navigation
                StaggeredListItem(
                  index: 1,
                  child: SettingsSection(
                    title: 'Settings',
                    children: [
                      SettingsTile(
                        title: 'Appearance',
                        description: 'Colors, intensity, animations',
                        icon: LucideIcons.palette,
                        iconColor: AppColors.getAccentColor(13, intensity), // Purple
                        onTap: () => context.push('/settings/appearance'),
                      ),
                      SettingsTile(
                        title: 'Formats',
                        description: 'Date, currency, calendar',
                        icon: LucideIcons.calendar,
                        iconColor: AppColors.getAccentColor(11, intensity), // Yellow
                        onTap: () => context.push('/settings/formats'),
                      ),
                      SettingsTile(
                        title: 'Preferences',
                        description: 'Haptics, start screen',
                        icon: LucideIcons.settings,
                        iconColor: AppColors.getAccentColor(7, intensity), // Green
                        onTap: () => context.push('/settings/preferences'),
                      ),
                      SettingsTile(
                        title: 'Transactions',
                        description: 'Defaults, validation, display',
                        icon: LucideIcons.receipt,
                        iconColor: AppColors.getAccentColor(5, intensity), // Teal
                        onTap: () => context.push('/settings/transactions'),
                      ),
                      SettingsTile(
                        title: 'Reset to Defaults',
                        description: 'Restore all settings',
                        icon: LucideIcons.rotateCcw,
                        iconColor: AppColors.expense,
                        onTap: () => _handleResetSettings(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // More Section
                StaggeredListItem(
                  index: 2,
                  child: SettingsSection(
                    title: 'More',
                    children: [
                      SettingsTile(
                        title: 'Coming Soon',
                        description: 'Feature roadmap',
                        icon: LucideIcons.sparkles,
                        iconColor: AppColors.getAccentColor(15, intensity), // Orange
                        onTap: () => context.push('/settings/coming-soon'),
                      ),
                      SettingsTile(
                        title: 'About',
                        description: 'App version',
                        icon: LucideIcons.info,
                        iconColor: AppColors.getAccentColor(0, intensity), // White
                        onTap: () => context.push('/settings/about'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
