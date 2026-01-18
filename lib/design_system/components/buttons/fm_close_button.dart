import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

/// A standardized close button used in form screens and modals.
class FMCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  const FMCloseButton({
    super.key,
    required this.onTap,
    this.icon = LucideIcons.x,
    this.iconColor,
    this.backgroundColor,
    this.size = AppSpacing.closeButtonSize,
  });

  /// Factory constructor for a close button that navigates back.
  factory FMCloseButton.pop(BuildContext context, {IconData? icon}) {
    return FMCloseButton(
      onTap: () => Navigator.of(context).pop(),
      icon: icon ?? LucideIcons.x,
    );
  }

  /// Factory constructor for a plus/add button.
  factory FMCloseButton.add({
    required VoidCallback onTap,
  }) {
    return FMCloseButton(
      onTap: onTap,
      icon: LucideIcons.plus,
      iconColor: AppColors.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          color: iconColor ?? AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
