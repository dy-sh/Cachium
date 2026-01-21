import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class ResetDatabaseResult {
  final bool confirmed;
  final bool resetSettings;

  const ResetDatabaseResult({
    required this.confirmed,
    required this.resetSettings,
  });
}

class ResetDatabaseDialog extends StatefulWidget {
  const ResetDatabaseDialog({super.key});

  @override
  State<ResetDatabaseDialog> createState() => _ResetDatabaseDialogState();
}

class _ResetDatabaseDialogState extends State<ResetDatabaseDialog> {
  bool _resetSettings = false;

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
              color: AppColors.expense.withOpacity(0.1),
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
            'Reset Database?',
            style: AppTypography.h4,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently delete all transactions, accounts, and categories. You will be returned to the setup screen to start fresh.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () {
              setState(() {
                _resetSettings = !_resetSettings;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _resetSettings
                        ? AppColors.expense
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _resetSettings
                          ? AppColors.expense
                          : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: _resetSettings
                      ? Icon(
                          LucideIcons.check,
                          size: 16,
                          color: AppColors.textPrimary,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Also reset app settings',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const ResetDatabaseResult(confirmed: false, resetSettings: false),
          ),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            ResetDatabaseResult(confirmed: true, resetSettings: _resetSettings),
          ),
          child: Text(
            'Reset',
            style: AppTypography.button.copyWith(
              color: AppColors.expense,
            ),
          ),
        ),
      ],
    );
  }
}

Future<ResetDatabaseResult?> showResetDatabaseDialog({
  required BuildContext context,
}) {
  return showDialog<ResetDatabaseResult>(
    context: context,
    builder: (context) => const ResetDatabaseDialog(),
  );
}
