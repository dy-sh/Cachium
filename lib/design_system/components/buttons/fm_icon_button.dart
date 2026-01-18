import 'package:flutter/material.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../mixins/tap_scale_mixin.dart';

class FMIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final bool showBorder;

  const FMIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = AppSpacing.iconButtonSize,
    this.showBorder = false,
  });

  @override
  State<FMIconButton> createState() => _FMIconButtonState();
}

class _FMIconButtonState extends State<FMIconButton>
    with SingleTickerProviderStateMixin, TapScaleMixin {
  @override
  double get tapScale => AppAnimations.tapScaleLarge;

  @override
  bool get isTapEnabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: handleTapDown,
      onTapUp: handleTapUp,
      onTapCancel: handleTapCancel,
      child: buildScaleTransition(
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: widget.showBorder
                ? Border.all(color: AppColors.border)
                : null,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: widget.iconColor ?? AppColors.textPrimary,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
