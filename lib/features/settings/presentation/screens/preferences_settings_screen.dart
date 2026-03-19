import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../design_system/design_system.dart';
import '../providers/settings_provider.dart';
import 'appearance_section.dart';
import 'security_section.dart';

class PreferencesSettingsScreen extends ConsumerWidget {
  const PreferencesSettingsScreen({super.key});

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
            const SettingsHeader(title: 'Preferences'),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppearanceSection(),
                    const SizedBox(height: AppSpacing.xl),
                    const SecuritySection(),
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
}
