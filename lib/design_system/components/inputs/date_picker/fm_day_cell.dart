import 'package:flutter/material.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../mixins/tap_scale_mixin.dart';

/// A single day cell in the calendar grid.
class FMDayCell extends StatefulWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final VoidCallback onTap;

  const FMDayCell({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<FMDayCell> createState() => _FMDayCellState();
}

class _FMDayCellState extends State<FMDayCell>
    with SingleTickerProviderStateMixin, TapScaleMixin {
  @override
  double get tapScale => AppAnimations.tapScaleLarge;

  @override
  bool get isTapEnabled => !widget.isDisabled;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDisabled
        ? AppColors.textTertiary.withOpacity(0.5)
        : widget.isSelected
            ? AppColors.background
            : widget.isToday
                ? AppColors.accentPrimary
                : AppColors.textPrimary;

    return GestureDetector(
      onTapDown: handleTapDown,
      onTapUp: (details) {
        handleTapUp(details);
        if (!widget.isDisabled) {
          widget.onTap();
        }
      },
      onTapCancel: handleTapCancel,
      child: buildScaleTransition(
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          width: AppSpacing.calendarDayCellSize,
          height: AppSpacing.calendarDayCellSize,
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.accentPrimary : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentPrimary.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
            border: widget.isToday && !widget.isSelected
                ? Border.all(color: AppColors.accentPrimary, width: 1)
                : null,
          ),
          child: Center(
            child: Text(
              '${widget.day}',
              style: AppTypography.labelMedium.copyWith(
                color: textColor,
                fontWeight: widget.isSelected || widget.isToday
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
