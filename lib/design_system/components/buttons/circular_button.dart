import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';

/// A standardized close button used in form screens and modals.
class CircularButton extends ConsumerWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final bool useAccentColor;

  const CircularButton({
    super.key,
    required this.onTap,
    this.icon = LucideIcons.x,
    this.iconColor,
    this.backgroundColor,
    this.size = AppSpacing.closeButtonSize,
    this.useAccentColor = false,
  });

  /// Factory constructor for a close button that navigates back.
  factory CircularButton.pop(BuildContext context, {IconData? icon}) {
    return CircularButton(
      onTap: () => Navigator.of(context).pop(),
      icon: icon ?? LucideIcons.x,
    );
  }

  /// Factory constructor for a plus/add button that uses accent color.
  factory CircularButton.add({
    required VoidCallback onTap,
  }) {
    return CircularButton(
      onTap: onTap,
      icon: LucideIcons.plus,
      useAccentColor: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);
    final effectiveIconColor = useAccentColor
        ? accentColor
        : (iconColor ?? AppColors.textSecondary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: effectiveIconColor,
          size: 20,
        ),
      ),
    );
  }
}
