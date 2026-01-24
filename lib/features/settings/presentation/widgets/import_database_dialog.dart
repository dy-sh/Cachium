import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class ImportDatabaseDialog extends StatelessWidget {
  const ImportDatabaseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.expense.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.alertTriangle,
              size: 20,
              color: AppColors.expense,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Import Database?',
            style: AppTypography.h4,
          ),
        ],
      ),
      content: Text(
        'All current data will be permanently deleted and replaced with the imported database. This action cannot be undone.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Import',
            style: AppTypography.button.copyWith(
              color: AppColors.expense,
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool?> showImportDatabaseDialog({
  required BuildContext context,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const ImportDatabaseDialog(),
  );
}
