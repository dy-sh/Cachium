import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/color_picker_grid.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_toggle_tile.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
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
                        Text('Appearance', style: AppTypography.h3),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Colors Section
                  SettingsSection(
                    title: 'Colors',
                    children: [
                      _buildColorIntensityTile(context, ref, settings),
                      _buildAccentColorTile(context, ref, settings),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Animations Section
                  SettingsSection(
                    title: 'Animations',
                    children: [
                      SettingsToggleTile(
                        title: 'Tab Transitions',
                        description: 'Fade effect when switching tabs',
                        value: settings.tabTransitionsEnabled,
                        onChanged: (value) => ref.read(settingsProvider.notifier).setTabTransitionsEnabled(value),
                      ),
                      SettingsToggleTile(
                        title: 'Form Animations',
                        description: 'Slide-in effects for forms and modals',
                        value: settings.formAnimationsEnabled,
                        onChanged: (value) => ref.read(settingsProvider.notifier).setFormAnimationsEnabled(value),
                      ),
                      SettingsToggleTile(
                        title: 'Balance Counters',
                        description: 'Animate balance numbers when they change',
                        value: settings.balanceCountersEnabled,
                        onChanged: (value) => ref.read(settingsProvider.notifier).setBalanceCountersEnabled(value),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorIntensityTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Color Intensity', style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'Vibrant or muted colors throughout the app',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildSegmentedControl(
            options: ['Bright', 'Dim'],
            selectedIndex: settings.colorIntensity == ColorIntensity.bright ? 0 : 1,
            onChanged: (index) {
              ref.read(settingsProvider.notifier).setColorIntensity(
                    index == 0 ? ColorIntensity.bright : ColorIntensity.dim,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccentColorTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accent Color', style: AppTypography.bodyMedium),
          const SizedBox(height: 2),
          Text(
            'Affects selected states, buttons, highlights',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          ColorPickerGrid(
            colors: AppColors.accentOptions,
            selectedColor: settings.accentColor,
            onColorSelected: (color) {
              ref.read(settingsProvider.notifier).setAccentColor(color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                options[index],
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
