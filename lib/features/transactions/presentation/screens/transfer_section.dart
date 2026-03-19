import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../design_system/components/inputs/amount_input.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/transaction_form_provider.dart';
import '../widgets/account_selector.dart';

class TransferSection extends ConsumerWidget {
  final TransactionFormState formState;
  final ValueChanged<String?> onDestinationAccountChanged;
  final ValueChanged<double> onDestinationAmountChanged;
  final VoidCallback onCreateAccount;

  const TransferSection({
    super.key,
    required this.formState,
    required this.onDestinationAccountChanged,
    required this.onDestinationAmountChanged,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrEmpty;
    final recentAccountIds = ref.watch(recentlyUsedAccountIdsProvider);
    final accountsFoldedCount = ref.watch(accountsFoldedCountProvider);
    final showAddAccountButton = ref.watch(showAddAccountButtonProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Text('To Account', style: AppTypography.labelMedium),
        if (formState.sameAccountError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              formState.sameAccountError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        AccountSelector(
          accounts: accounts,
          selectedId: formState.destinationAccountId,
          recentAccountIds: recentAccountIds,
          initialVisibleCount: accountsFoldedCount,
          excludeAccountId: formState.accountId,
          onChanged: onDestinationAccountChanged,
          onCreatePressed: showAddAccountButton
              ? () => onCreateAccount()
              : null,
        ),
        // Cross-currency destination amount
        if (formState.destinationAmount != null)
          _DestinationAmountInput(
            formState: formState,
            onDestinationAmountChanged: onDestinationAmountChanged,
          ),
      ],
    );
  }
}

class _DestinationAmountInput extends ConsumerWidget {
  final TransactionFormState formState;
  final ValueChanged<double> onDestinationAmountChanged;

  const _DestinationAmountInput({
    required this.formState,
    required this.onDestinationAmountChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dstAccount = formState.destinationAccountId != null
        ? ref.watch(accountByIdProvider(formState.destinationAccountId!))
        : null;
    final dstCurrency = dstAccount?.currencyCode ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Text('Destination Amount ($dstCurrency)', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        AmountInput(
          key: ValueKey('dest_amount_${formState.destinationAccountId}_$dstCurrency'),
          initialValue: formState.destinationAmount,
          transactionType: 'transfer',
          currencyCode: dstCurrency,
          autofocus: false,
          onChanged: onDestinationAmountChanged,
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            'Auto-calculated from exchange rate. Adjust if needed.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
