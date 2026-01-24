import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';

/// Navigation button for calendar month navigation.
class DatePickerNavigationButton extends ConsumerStatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const DatePickerNavigationButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  ConsumerState<DatePickerNavigationButton> createState() =>
      _FMDatePickerNavigationButtonState();
}

class _FMDatePickerNavigationButtonState
    extends ConsumerState<DatePickerNavigationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = ref.watch(formAnimationsEnabledProvider);
    final backgroundColor =
        _isPressed ? AppColors.surfaceLight : AppColors.background;

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
                color: AppColors.textSecondary,
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
                color: AppColors.textSecondary,
              ),
            ),
    );
  }
}
