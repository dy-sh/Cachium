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
                      Text('Appearance', style: AppTypography.h3),
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
                    // Colors Section
                    SettingsSection(
                      title: 'Colors',
                      children: [
                        _buildColorIntensityTile(context, ref, settings),
                        _buildAccentColorTile(context, ref, settings),
                        _buildAccountCardStyleTile(context, ref, settings),
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
                  ],
                ),
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
      (ColorIntensity.neon, 'Neon', 'Electric, ultra-vibrant'),
    ];

    return Column(
      children: palettes.map((palette) {
        final (intensity, name, description) = palette;
        final isSelected = settings.colorIntensity == intensity;
        // Pick 6 distinct colors spread across the color wheel (60° apart)
        final accentOptions = AppColors.getAccentOptions(intensity);
        final previewColors = [
          accentOptions[1],   // red (0°)
          accentOptions[5],   // yellow (60°)
          accentOptions[9],   // green (120°)
          accentOptions[13],  // cyan (180°)
          accentOptions[17],  // blue (240°)
          accentOptions[21],  // magenta (300°)
        ];

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
              final index = accentOptions.indexWhere((c) => c.toARGB32() == color.toARGB32());
              if (index >= 0) {
                ref.read(settingsProvider.notifier).setAccentColorIndex(index);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCardStyleTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    final styles = [
      (AccountCardStyle.dim, 'Dim'),
      (AccountCardStyle.bright, 'Bright'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Cards', style: AppTypography.bodyMedium),
          const SizedBox(height: 2),
          Text(
            'Background style for account cards',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: styles.map((style) {
              final (cardStyle, name) = style;
              final isSelected = settings.accountCardStyle == cardStyle;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(settingsProvider.notifier).setAccountCardStyle(cardStyle);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: cardStyle == AccountCardStyle.dim ? AppSpacing.sm : 0),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.textPrimary : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildCardPreview(settings.colorIntensity, cardStyle),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          name,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(ColorIntensity intensity, AccountCardStyle cardStyle) {
    final categoryColors = AppColors.getCategoryColors(intensity);
    final previewColor = categoryColors[9]; // orange/light brown
    final bgOpacity = AppColors.getBgOpacity(intensity);

    final gradientStart = cardStyle == AccountCardStyle.bright ? 0.6 : 0.35;
    final gradientEnd = cardStyle == AccountCardStyle.bright ? 0.3 : 0.15;
    final circleOpacity = cardStyle == AccountCardStyle.bright ? 0.3 : 0.15;

    return Container(
      height: 48,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            previewColor.withValues(alpha: bgOpacity * gradientStart),
            previewColor.withValues(alpha: bgOpacity * gradientEnd),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -12,
            right: -12,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: previewColor.withValues(alpha: bgOpacity * circleOpacity),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: previewColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    LucideIcons.landmark,
                    color: AppColors.background,
                    size: 10,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 6,
                        width: 50,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 4,
                        width: 30,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
