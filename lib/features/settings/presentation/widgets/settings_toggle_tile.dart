import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/inputs/fm_switch.dart';

class SettingsToggleTile extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? iconColor;
  final Color? activeColor;

  const SettingsToggleTile({
    super.key,
    required this.title,
    this.description,
    required this.value,
    this.onChanged,
    this.icon,
    this.iconColor,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.textSecondary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FMSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: activeColor,
            ),
          ],
        ),
      ),
    );
  }
}
