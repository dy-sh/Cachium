import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';

/// Icon button used in the date picker header.
class FMDatePickerIconButton extends ConsumerStatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color accentColor;

  const FMDatePickerIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.accentColor,
    this.isActive = false,
  });

  @override
  ConsumerState<FMDatePickerIconButton> createState() =>
      _FMDatePickerIconButtonState();
}

class _FMDatePickerIconButtonState extends ConsumerState<FMDatePickerIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = ref.watch(formAnimationsEnabledProvider);
    final backgroundColor = widget.isActive
        ? widget.accentColor
        : _isPressed
            ? AppColors.surfaceLight
            : AppColors.background;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: animationsEnabled
          ? AnimatedContainer(
              duration: AppAnimations.fast,
              width: AppSpacing.calendarHeaderButtonSize,
              height: AppSpacing.calendarHeaderButtonSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: widget.isActive
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
            )
          : Container(
              width: AppSpacing.calendarHeaderButtonSize,
              height: AppSpacing.calendarHeaderButtonSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: widget.isActive
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
            ),
    );
  }
}
