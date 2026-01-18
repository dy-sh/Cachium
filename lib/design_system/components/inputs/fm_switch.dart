import 'package:flutter/material.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';

class FMSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const FMSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = value
        ? (activeColor ?? AppColors.textPrimary)
        : AppColors.surface;
    final thumbColor = value
        ? AppColors.background
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
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
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
