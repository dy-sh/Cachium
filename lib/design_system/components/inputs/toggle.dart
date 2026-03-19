import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';

/// A custom animated toggle switch styled to match the design system.
class Toggle extends ConsumerWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final String? semanticLabel;

  const Toggle({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);
    final trackColor = value
        ? (activeColor ?? accentColor)
        : AppColors.surface;
    final thumbColor = value
        ? AppColors.background
        : AppColors.textSecondary;

    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          width: AppSpacing.toggleWidth,
          height: AppSpacing.toggleHeight,
          padding: const EdgeInsets.all(AppSpacing.togglePadding),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value ? Colors.transparent : AppColors.border,
              width: 1,
            ),
          ),
          child: AnimatedAlign(
            duration: AppAnimations.normal,
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: thumbColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
