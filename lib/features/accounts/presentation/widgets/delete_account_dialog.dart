import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
import '../../data/models/account.dart';

enum DeleteAccountAction {
  deleteWithTransactions,
  moveTransactions,
  cancel,
}

class DeleteAccountDialog extends ConsumerWidget {
  final Account account;
  final int transactionCount;

  const DeleteAccountDialog({
    super.key,
    required this.account,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionText = transactionCount == 1 ? 'transaction' : 'transactions';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Delete "${account.name}"?',
        style: AppTypography.h4,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This account has $transactionCount $transactionText. Choose what to do with them:',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Option 1: Move transactions
          _buildOption(
            context: context,
            ref: ref,
            icon: LucideIcons.arrowRightLeft,
            iconColor: AppColors.accentPrimary,
            title: 'Move Transactions',
            description: 'Reassign $transactionText to another account before deleting',
            action: DeleteAccountAction.moveTransactions,
          ),

          const SizedBox(height: AppSpacing.md),

          // Option 2: Delete all
          _buildOption(
            context: context,
            ref: ref,
            icon: LucideIcons.trash2,
            iconColor: AppColors.expense,
            title: 'Delete Everything',
            description: 'Remove "${account.name}" and all its $transactionText',
            action: DeleteAccountAction.deleteWithTransactions,
            isDanger: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, DeleteAccountAction.cancel),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required DeleteAccountAction action,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, action),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger
                ? AppColors.expense.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDanger ? AppColors.expense : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<DeleteAccountAction?> showDeleteAccountDialog({
  required BuildContext context,
  required Account account,
  required int transactionCount,
}) {
  return showDialog<DeleteAccountAction>(
    context: context,
    builder: (context) => DeleteAccountDialog(
      account: account,
      transactionCount: transactionCount,
    ),
  );
}

Future<bool?> showSimpleDeleteAccountDialog({
  required BuildContext context,
  required Account account,
}) async {
  final result = await showConfirmationDialog(
    context: context,
    title: 'Delete Account',
    message: 'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
    confirmLabel: 'Delete',
    isDestructive: true,
  );
  return result;
}

class MoveTransactionsDialog extends ConsumerWidget {
  final Account sourceAccount;
  final List<Account> availableAccounts;

  const MoveTransactionsDialog({
    super.key,
    required this.sourceAccount,
    required this.availableAccounts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Move Transactions',
        style: AppTypography.h4,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select the account to move transactions to:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableAccounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final account = availableAccounts[index];
                  return _AccountOption(
                    account: account,
                    onTap: () => Navigator.pop(context, account),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountOption extends ConsumerWidget {
  final Account account;
  final VoidCallback onTap;

  const _AccountOption({
    required this.account,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: account.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                account.icon,
                size: 18,
                color: account.color,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    account.type.displayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

Future<Account?> showMoveTransactionsDialog({
  required BuildContext context,
  required Account sourceAccount,
  required List<Account> availableAccounts,
}) {
  return showDialog<Account>(
    context: context,
    builder: (context) => MoveTransactionsDialog(
      sourceAccount: sourceAccount,
      availableAccounts: availableAccounts,
    ),
  );
}
