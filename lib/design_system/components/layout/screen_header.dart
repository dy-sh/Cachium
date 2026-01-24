import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// A reusable screen header with title and optional action button.
///
/// Used at the top of main screens like Accounts and Transactions.
class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onActionPressed;
  final IconData actionIcon;
  final Color? actionIconColor;

  const ScreenHeader({
    super.key,
    required this.title,
    this.onActionPressed,
    this.actionIcon = LucideIcons.plus,
    this.actionIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.h2),
          if (onActionPressed != null)
            GestureDetector(
              onTap: onActionPressed,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  actionIcon,
                  color: actionIconColor ?? AppColors.accentPrimary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
