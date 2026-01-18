import 'package:flutter/material.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../mixins/tap_scale_mixin.dart';

class FMChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final IconData? icon;
  final Color? iconColor;

  const FMChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.icon,
    this.iconColor,
  });

  @override
  State<FMChip> createState() => _FMChipState();
}

class _FMChipState extends State<FMChip>
    with SingleTickerProviderStateMixin, TapScaleMixin {
  @override
  double get tapScale => AppAnimations.tapScaleSmall;

  @override
  bool get isTapEnabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.selectedColor ?? AppColors.textPrimary;
    final borderColor = widget.isSelected ? selectedColor : AppColors.border;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: handleTapDown,
      onTapUp: handleTapUp,
      onTapCancel: handleTapCancel,
      child: buildScaleTransition(
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? selectedColor.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected
                      ? selectedColor
                      : widget.iconColor ?? AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                widget.label,
                style: AppTypography.labelMedium.copyWith(
                  color: widget.isSelected
                      ? selectedColor
                      : AppColors.textPrimary,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
