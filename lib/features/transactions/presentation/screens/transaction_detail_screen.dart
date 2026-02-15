import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transactions_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(transactionByIdProvider(transactionId));
    final intensity = ref.watch(colorIntensityProvider);

    if (transaction == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              FormHeader(
                title: 'Transaction',
                onClose: () => context.pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text('Transaction not found'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final account = ref.watch(accountByIdProvider(transaction.accountId));
    final destAccount = transaction.destinationAccountId != null
        ? ref.watch(accountByIdProvider(transaction.destinationAccountId!))
        : null;
    final isTransfer = transaction.isTransfer;
    final color = AppColors.getTransactionColor(transaction.type.name, intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = isTransfer
        ? AppColors.getTransactionColor('transfer', intensity)
        : (category?.getColor(intensity) ?? AppColors.textSecondary);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Transaction',
              onClose: () => context.pop(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/transaction/${transaction.id}/edit'),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.pencil,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => _deleteAndShowUndo(context, ref, transaction),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: AppColors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Amount display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: bgOpacity * 0.4),
                            color.withValues(alpha: bgOpacity * 0.15),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: bgOpacity),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isTransfer
                                  ? LucideIcons.arrowLeftRight
                                  : (category?.icon ?? Icons.circle),
                              color: categoryColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            isTransfer
                                ? CurrencyFormatter.format(transaction.amount)
                                : CurrencyFormatter.formatWithSign(
                                    transaction.amount, transaction.type.name),
                            style: AppTypography.moneyLarge.copyWith(
                              color: color,
                              fontSize: 34,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              transaction.type.displayName,
                              style: AppTypography.labelSmall.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Details
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          if (!isTransfer && category != null)
                            _DetailRow(
                              icon: LucideIcons.tag,
                              label: 'Category',
                              value: category.name,
                              valueColor: categoryColor,
                            ),
                          if (isTransfer) ...[
                            _DetailRow(
                              icon: LucideIcons.arrowUpRight,
                              label: 'From',
                              value: account?.name ?? 'Unknown',
                            ),
                            _DetailRow(
                              icon: LucideIcons.arrowDownLeft,
                              label: 'To',
                              value: destAccount?.name ?? 'Unknown',
                            ),
                          ] else
                            _DetailRow(
                              icon: LucideIcons.wallet,
                              label: 'Account',
                              value: account?.name ?? 'Unknown',
                            ),
                          _DetailRow(
                            icon: LucideIcons.calendar,
                            label: 'Date',
                            value: DateFormatter.formatFull(transaction.date),
                          ),
                          if (transaction.merchant != null &&
                              transaction.merchant!.isNotEmpty)
                            _DetailRow(
                              icon: LucideIcons.store,
                              label: 'Merchant',
                              value: transaction.merchant!,
                            ),
                          if (transaction.note != null &&
                              transaction.note!.isNotEmpty)
                            _DetailRow(
                              icon: LucideIcons.stickyNote,
                              label: 'Note',
                              value: transaction.note!,
                              isLast: true,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAndShowUndo(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final notifier = ref.read(transactionsProvider.notifier);
    await notifier.deleteTransaction(transaction.id);

    if (context.mounted) {
      context.pop();
      context.showUndoNotification(
        'Transaction deleted',
        () => notifier.restoreTransaction(transaction),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
