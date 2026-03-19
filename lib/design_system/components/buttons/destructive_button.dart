import 'package:flutter/material.dart';
import '../../../core/animations/haptic_helper.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../mixins/tap_scale_mixin.dart';
import '../feedback/loading_indicator.dart';

/// A destructive action button (red) with loading state and tap scale animation.
class DestructiveButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final bool isOutlined;
  final IconData? icon;
  final String? semanticLabel;

  const DestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.isOutlined = false,
    this.icon,
    this.semanticLabel,
  });

  @override
  State<DestructiveButton> createState() => _DestructiveButtonState();
}

class _DestructiveButtonState extends State<DestructiveButton>
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
    final bgColor = widget.isOutlined ? Colors.transparent : AppColors.expense;
    final txtColor = widget.isOutlined ? AppColors.expense : Colors.white;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
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
              border: widget.isOutlined
                  ? Border.all(color: AppColors.expense)
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? LoadingDots(
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
      ),
    );
  }
}
