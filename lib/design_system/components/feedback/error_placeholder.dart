import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// A compact error placeholder for use in `.when()` error callbacks.
class ErrorPlaceholder extends StatelessWidget {
  final String message;

  const ErrorPlaceholder({super.key, this.message = 'Failed to load'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
      ),
    );
  }
}
