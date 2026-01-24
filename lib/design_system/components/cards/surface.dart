import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';
import '../../mixins/tap_scale_mixin.dart';

class Surface extends ConsumerStatefulWidget {
  final Widget child;
  final bool isSelected;
  final Color? borderColor;
  final Color? selectedBorderColor;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? width;
  final double? height;

  const Surface({
    super.key,
    required this.child,
    this.isSelected = false,
    this.borderColor,
    this.selectedBorderColor,
    this.onTap,
    this.padding,
    this.width,
    this.height,
  });

  @override
  ConsumerState<Surface> createState() => _FMCardState();
}

class _FMCardState extends ConsumerState<Surface>
    with SingleTickerProviderStateMixin, TapScaleMixin {
  @override
  double get tapScale => AppAnimations.tapScaleCard;

  @override
  bool get isTapEnabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);
    final borderColor = widget.isSelected
        ? (widget.selectedBorderColor ?? widget.borderColor ?? accentColor)
        : widget.borderColor ?? AppColors.border;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: handleTapDown,
      onTapUp: handleTapUp,
      onTapCancel: handleTapCancel,
      child: buildScaleTransition(
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
