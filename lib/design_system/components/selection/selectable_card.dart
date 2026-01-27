import 'package:flutter/material.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// A reusable selectable card component with animated selection state.
///
/// Displays an icon and content with a gradient background when selected,
/// or a solid surface background when not selected.
class SelectableCard extends StatelessWidget {
  final bool isSelected;
  final Color color;
  final double bgOpacity;
  final IconData icon;
  final Widget content;
  final Widget? trailing;
  final VoidCallback onTap;
  final EdgeInsets padding;

  /// Custom color for the icon container when not selected.
  /// Defaults to [AppColors.surfaceLight].
  final Color? unselectedIconBgColor;

  /// Custom color for the icon when not selected.
  /// Defaults to [AppColors.textSecondary].
  final Color? unselectedIconColor;

  /// Custom color for the icon when selected.
  /// Defaults to [AppColors.background].
  final Color? selectedIconColor;

  const SelectableCard({
    super.key,
    required this.isSelected,
    required this.color,
    required this.bgOpacity,
    required this.icon,
    required this.content,
    this.trailing,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    this.unselectedIconBgColor,
    this.unselectedIconColor,
    this.selectedIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: AppRadius.smAll,
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: bgOpacity * 0.4),
                    color.withValues(alpha: bgOpacity * 0.2),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.surface,
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.9)
                    : (unselectedIconBgColor ?? AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 12,
                color: isSelected
                    ? (selectedIconColor ?? AppColors.background)
                    : (unselectedIconColor ?? AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: content),
            if (trailing != null) ...[
              const SizedBox(width: 2),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
