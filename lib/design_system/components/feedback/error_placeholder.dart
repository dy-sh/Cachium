import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// A compact error placeholder for use in `.when()` error callbacks.
class ErrorPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorPlaceholder({
    super.key,
    this.message = 'Failed to load',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Try again',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
