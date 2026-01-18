import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/animations/staggered_list.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final customCategoryCount = categories.where((c) => c.isCustom).length;

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
                // Categories Section
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
                        iconColor: AppColors.accentOptions[1], // Cyan
                        onTap: () => context.push('/settings/categories'),
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
                        iconColor: AppColors.accentOptions[13], // Purple
                        onTap: () => context.push('/settings/appearance'),
                      ),
                      SettingsTile(
                        title: 'Formats',
                        description: 'Date, currency, calendar',
                        icon: LucideIcons.calendar,
                        iconColor: AppColors.accentOptions[11], // Yellow
                        onTap: () => context.push('/settings/formats'),
                      ),
                      SettingsTile(
                        title: 'Preferences',
                        description: 'Haptics, start screen',
                        icon: LucideIcons.settings,
                        iconColor: AppColors.accentOptions[7], // Green
                        onTap: () => context.push('/settings/preferences'),
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
                        iconColor: AppColors.accentOptions[15], // Orange
                        onTap: () => context.push('/settings/coming-soon'),
                      ),
                      SettingsTile(
                        title: 'About',
                        description: 'App version',
                        icon: LucideIcons.info,
                        iconColor: AppColors.accentOptions[0], // White
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
