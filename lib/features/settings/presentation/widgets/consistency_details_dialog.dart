import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/database_consistency.dart';

class ConsistencyDetailsDialog extends StatelessWidget {
  final DatabaseConsistency consistency;

  const ConsistencyDetailsDialog({
    super.key,
    required this.consistency,
  });

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
              color: consistency.isConsistent
                  ? AppColors.income.withValues(alpha: 0.1)
                  : AppColors.expense.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              consistency.isConsistent
                  ? LucideIcons.checkCircle
                  : LucideIcons.alertTriangle,
              size: 20,
              color: consistency.isConsistent
                  ? AppColors.income
                  : AppColors.expense,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Consistency Details',
              style: AppTypography.h4,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < consistency.allChecks.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                ),
              _CheckRow(check: consistency.allChecks[i]),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final ConsistencyCheck check;

  const _CheckRow({
    required this.check,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = check.hasIssues ? AppColors.expense : AppColors.income;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            check.icon,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              check.label,
              style: AppTypography.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            check.count.toString(),
            style: AppTypography.bodyMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showConsistencyDetailsDialog({
  required BuildContext context,
  required DatabaseConsistency consistency,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => ConsistencyDetailsDialog(consistency: consistency),
  );
}
