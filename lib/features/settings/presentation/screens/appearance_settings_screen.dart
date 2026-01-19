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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color Palette', style: AppTypography.bodyMedium),
          const SizedBox(height: 2),
          Text(
            'Choose the color style for the app',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPaletteSelector(ref, settings),
        ],
      ),
    );
  }

  Widget _buildPaletteSelector(WidgetRef ref, AppSettings settings) {
    final palettes = [
      (ColorIntensity.prism, 'Prism', 'Vivid, refracted spectrum'),
      (ColorIntensity.zen, 'Zen', 'Soft, peaceful tones'),
      (ColorIntensity.pastel, 'Pastel', 'Light, calming colors'),
      (ColorIntensity.neon, 'Neon', 'Electric, ultra-vibrant'),
      (ColorIntensity.vintage, 'Vintage', 'Retro, warm, nostalgic'),
    ];

    return Column(
      children: palettes.map((palette) {
        final (intensity, name, description) = palette;
        final isSelected = settings.colorIntensity == intensity;
        final previewColors = AppColors.getCategoryColors(intensity).take(6).toList();

        return GestureDetector(
          onTap: () {
            ref.read(settingsProvider.notifier).setColorIntensity(intensity);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.labelLarge.copyWith(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Color swatches preview
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: previewColors.map((color) {
                    return Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccentColorTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    final accentOptions = AppColors.getAccentOptions(settings.colorIntensity);

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
            colors: accentOptions,
            selectedColor: settings.accentColor,
            onColorSelected: (color) {
              ref.read(settingsProvider.notifier).setAccentColor(color);
            },
          ),
        ],
      ),
    );
  }

}
