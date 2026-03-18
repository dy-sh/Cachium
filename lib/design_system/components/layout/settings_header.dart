import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../buttons/circular_button.dart';

/// A reusable header for settings/sub-screens with a back button and title.
///
/// Replaces the duplicated back-button + title pattern used across 19+ screens.
class SettingsHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const SettingsHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircularButton(
                onTap: onBack ?? () => context.pop(),
                icon: LucideIcons.chevronLeft,
                size: AppSpacing.settingsBackButtonSize,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: AppTypography.h3),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
