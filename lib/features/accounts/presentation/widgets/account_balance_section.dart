import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/database_management_providers.dart';
import '../../../settings/presentation/widgets/recalculate_preview_dialog.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../providers/account_form_provider.dart';
import '../providers/accounts_provider.dart';

class AccountBalanceSection extends ConsumerWidget {
  final AccountFormState formState;
  final bool isEditing;
  final TextEditingController balanceController;
  final TextEditingController initialBalanceController;

  const AccountBalanceSection({
    super.key,
    required this.formState,
    required this.isEditing,
    required this.balanceController,
    required this.initialBalanceController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Currency', style: AppTypography.labelMedium),
            const SizedBox(width: AppSpacing.md),
            CurrencyCodeChip(
              currencyCode: formState.currencyCode,
              onTap: () {
                showCurrencyPickerSheet(
                  context: context,
                  selectedCode: formState.currencyCode,
                  onSelected: (code) {
                    ref.read(accountFormProvider.notifier).setCurrencyCode(code);
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        if (!isEditing) ...[
          Builder(builder: (context) {
            final symbol = Currency.symbolFromCode(formState.currencyCode);
            return InputField(
              label: 'Initial Balance',
              hint: '0.00',
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              prefix: Text(
                symbol,
                style: AppTypography.input.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onChanged: (value) {
                ref.read(accountFormProvider.notifier).setInitialBalance(
                      double.tryParse(value) ?? 0,
                    );
              },
            );
          }),
        ] else ...[
          Builder(builder: (context) {
            final symbol = Currency.symbolFromCode(formState.currencyCode);
            return InputField(
              key: ValueKey('initial_balance_${formState.editingAccountId}'),
              label: 'Initial Balance',
              hint: '0.00',
              controller: initialBalanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              prefix: Text(
                symbol,
                style: AppTypography.input.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onChanged: (value) {
                ref.read(accountFormProvider.notifier).setInitialBalance(
                      double.tryParse(value) ?? 0,
                    );
              },
            );
          }),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Icon(
                LucideIcons.wallet,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Current balance:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${Currency.symbolFromCode(formState.currencyCode)}${formState.currentBalance.toStringAsFixed(2)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.05),
              borderRadius: AppRadius.smAll,
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  size: 16,
                  color: AppColors.accentPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance may drift if transactions were edited. Use recalculate to fix.',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      GestureDetector(
                        onTap: () => _recalculateThisAccount(context, ref),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.calculator,
                              size: 14,
                              color: AppColors.accentPrimary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Recalculate balance',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _recalculateThisAccount(BuildContext context, WidgetRef ref) async {
    final formState = ref.read(accountFormProvider);
    if (formState.editingAccountId == null) return;

    final account = ref.read(accountByIdProvider(formState.editingAccountId!));
    if (account == null) return;

    final transactionsAsync = ref.read(transactionsProvider);
    final transactions = transactionsAsync.valueOrEmpty;
    final accountTransactions = transactions.where(
      (t) => t.accountId == account.id || t.destinationAccountId == account.id,
    );

    double transactionDelta = 0;
    for (final tx in accountTransactions) {
      if (tx.type == TransactionType.transfer) {
        if (tx.accountId == account.id) {
          transactionDelta -= tx.amount;
        }
        if (tx.destinationAccountId == account.id) {
          transactionDelta += tx.destinationAmount ?? tx.amount;
        }
      } else if (tx.accountId == account.id) {
        transactionDelta += tx.type == TransactionType.income ? tx.amount : -tx.amount;
      }
    }

    final expectedBalance = formState.initialBalance + transactionDelta;

    final change = BalanceChange(
      accountId: account.id,
      accountName: account.name,
      currencyCode: account.currencyCode,
      oldBalance: formState.currentBalance,
      newBalance: expectedBalance,
      initialBalance: formState.initialBalance,
      transactionDelta: transactionDelta,
    );

    final preview = RecalculatePreview(
      changes: [change],
      totalAccounts: 1,
    );

    final shouldApply = await showRecalculatePreviewDialog(
      context: context,
      preview: preview,
    );

    if (shouldApply == true && context.mounted) {
      final updatedAccount = account.copyWith(balance: expectedBalance);
      await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);

      ref.read(accountFormProvider.notifier).setTransactionDelta(transactionDelta);

      if (context.mounted) {
        context.showSuccessNotification('Balance updated');
      }
    }
  }
}
