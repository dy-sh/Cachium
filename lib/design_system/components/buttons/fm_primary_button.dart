import 'package:flutter/material.dart';
import '../../../core/animations/haptic_helper.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../mixins/tap_scale_mixin.dart';
import '../feedback/fm_loading_indicator.dart';

class FMPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const FMPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  State<FMPrimaryButton> createState() => _FMPrimaryButtonState();
}

class _FMPrimaryButtonState extends State<FMPrimaryButton>
    with SingleTickerProviderStateMixin, TapScaleMixin {
  @override
  double get tapScale => AppAnimations.tapScaleDefault;

  @override
  bool get isTapEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails details) {
    if (isTapEnabled) {
      handleTapDown(details);
      HapticHelper.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final bgColor = widget.backgroundColor ?? AppColors.textPrimary;
    final txtColor = widget.textColor ?? AppColors.background;

    return GestureDetector(
      onTap: isDisabled ? null : widget.onPressed,
      onTapDown: _handleTapDown,
      onTapUp: handleTapUp,
      onTapCancel: handleTapCancel,
      child: buildScaleTransition(
        child: AnimatedOpacity(
          duration: AppAnimations.normal,
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            height: AppSpacing.buttonHeight,
            width: widget.isExpanded ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded ? 0 : AppSpacing.buttonPadding,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.button,
            ),
            child: Center(
              child: widget.isLoading
                  ? FMLoadingDots(
                      color: txtColor,
                      size: 24,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: txtColor, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.label,
                          style: AppTypography.button.copyWith(color: txtColor),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
