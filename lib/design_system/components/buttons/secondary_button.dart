import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/haptic_helper.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';
import '../../mixins/tap_scale_mixin.dart';
import '../feedback/loading_indicator.dart';

/// An outlined secondary action button with loading state and tap scale animation.
class SecondaryButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final bool useAccentColor;
  final String? semanticLabel;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.useAccentColor = false,
    this.semanticLabel,
  });

  @override
  ConsumerState<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends ConsumerState<SecondaryButton>
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
    final accentColor = ref.watch(accentColorProvider);
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final borderColor = widget.useAccentColor ? accentColor : AppColors.border;
    final txtColor = widget.useAccentColor ? accentColor : AppColors.textPrimary;

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
              color: Colors.transparent,
              borderRadius: AppRadius.button,
              border: Border.all(color: borderColor),
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
