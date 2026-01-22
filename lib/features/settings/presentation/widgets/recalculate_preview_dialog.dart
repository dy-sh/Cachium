import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/database_management_providers.dart';

class RecalculatePreviewDialog extends ConsumerWidget {
  final RecalculatePreview preview;

  const RecalculatePreviewDialog({
    super.key,
    required this.preview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changedAccounts = preview.changedAccounts;

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
              color: AppColors.accentPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.calculator,
              size: 20,
              color: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              changedAccounts.isEmpty
                  ? 'No Changes Needed'
                  : 'Review Changes',
              style: AppTypography.h4,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (changedAccounts.isEmpty)
              Text(
                'All account balances are already correct based on their initial balance and transaction history.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else ...[
              Text(
                '${changedAccounts.length} account${changedAccounts.length == 1 ? '' : 's'} will be updated:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: changedAccounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final change = changedAccounts[index];
                    return _BalanceChangeCard(change: change);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            changedAccounts.isEmpty ? 'Close' : 'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (changedAccounts.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Apply',
              style: AppTypography.button.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceChangeCard extends StatelessWidget {
  final BalanceChange change;

  const _BalanceChangeCard({
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change.difference > 0;
    final diffColor = isPositive ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            change.accountName,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(change.oldBalance),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.arrowRight,
                size: 16,
                color: AppColors.textTertiary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'New',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(change.newBalance),
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${CurrencyFormatter.format(change.difference)}',
                style: AppTypography.labelMedium.copyWith(
                  color: diffColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<bool?> showRecalculatePreviewDialog({
  required BuildContext context,
  required RecalculatePreview preview,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => RecalculatePreviewDialog(preview: preview),
  );
}
