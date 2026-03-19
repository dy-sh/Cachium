import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';

/// General/appearance section containing haptic feedback toggle and start screen picker.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;
    if (settings == null) return const SizedBox.shrink();

    return SettingsSection(
      title: 'General',
      children: [
        SettingsToggleTile(
          title: 'Haptic Feedback',
          description: 'Vibration on button taps',
          value: settings.hapticFeedbackEnabled,
          onChanged: (value) => ref.read(settingsProvider.notifier).setHapticFeedbackEnabled(value),
        ),
        _buildStartScreenTile(context, ref, settings),
      ],
    );
  }

  Widget _buildStartScreenTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    final startScreenLabels = {
      StartScreen.home: 'Home',
      StartScreen.transactions: 'Transactions',
      StartScreen.accounts: 'Accounts',
    };
    return SettingsTile(
      title: 'Start Screen',
      description: 'Screen to show when opening the app',
      value: startScreenLabels[settings.startScreen],
      onTap: () => _showStartScreenPicker(context, ref, settings),
    );
  }

  void _showStartScreenPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = OptionPickerSheet(
      title: 'Start Screen',
      options: const ['Home', 'Transactions', 'Accounts'],
      selectedIndex: StartScreen.values.indexOf(settings.startScreen),
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setStartScreen(StartScreen.values[index]);
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

/// A generic option picker bottom sheet.
class OptionPickerSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const OptionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
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
