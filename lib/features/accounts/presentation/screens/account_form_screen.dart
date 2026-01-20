import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/fm_primary_button.dart';
import '../../../../design_system/components/layout/fm_form_header.dart';
import '../../../../design_system/components/inputs/fm_text_field.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/account.dart';
import '../providers/account_form_provider.dart';
import '../providers/accounts_provider.dart';
import '../widgets/delete_account_dialog.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final String? accountId;

  const AccountFormScreen({super.key, this.accountId});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  bool _initialized = false;
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _initialBalanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController();
    _initialBalanceController = TextEditingController();

    // Reset form when creating new account
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.accountId == null) {
        ref.read(accountFormProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  void _initializeForEdit() {
    if (_initialized || widget.accountId == null) return;

    final account = ref.read(accountByIdProvider(widget.accountId!));
    if (account != null) {
      ref.read(accountFormProvider.notifier).initForEdit(account);
      _nameController.text = account.name;
      _balanceController.text = account.balance.toString();
      _initialBalanceController.text = account.initialBalance.toString();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize for edit mode after the first frame
    if (widget.accountId != null && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeForEdit();
        if (mounted) setState(() {});
      });
    }

    final formState = ref.watch(accountFormProvider);
    final isEditing = formState.isEditing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FMFormHeader(
              title: isEditing ? 'Edit Account' : 'New Account',
              onClose: () => context.pop(),
              trailing: isEditing
                  ? GestureDetector(
                      onTap: () => _showDeleteConfirmation(context),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.expense,
                        ),
                      ),
                    )
                  : null,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Type', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.md),
                    _AccountTypeGrid(
                      selectedType: formState.type,
                      onChanged: (type) {
                        ref.read(accountFormProvider.notifier).setType(type);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    FMTextField(
                      key: ValueKey('name_${formState.editingAccountId}'),
                      label: 'Account Name',
                      hint: 'Enter account name...',
                      controller: _nameController,
                      autofocus: false,
                      onChanged: (value) {
                        ref.read(accountFormProvider.notifier).setName(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (!isEditing) ...[
                      FMTextField(
                        label: 'Initial Balance',
                        hint: '0.00',
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        prefix: Text(
                          '\$',
                          style: AppTypography.input.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(accountFormProvider.notifier).setInitialBalance(
                                double.tryParse(value) ?? 0,
                              );
                        },
                      ),
                    ] else ...[
                      // When editing, show current balance as read-only
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Balance', style: AppTypography.labelMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: AppRadius.mdAll,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '\$${formState.currentBalance.toStringAsFixed(2)}',
                                  style: AppTypography.moneyMedium,
                                ),
                                const Spacer(),
                                Text(
                                  'Stored in database',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Initial balance (editable in edit mode)
                      FMTextField(
                        key: ValueKey('initial_balance_${formState.editingAccountId}'),
                        label: 'Initial Balance',
                        hint: '0.00',
                        controller: _initialBalanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        prefix: Text(
                          '\$',
                          style: AppTypography.input.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(accountFormProvider.notifier).setInitialBalance(
                                double.tryParse(value) ?? 0,
                              );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Hint about recalculation
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withOpacity(0.05),
                          borderRadius: AppRadius.smAll,
                          border: Border.all(
                            color: AppColors.accentPrimary.withOpacity(0.2),
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
                                    onTap: () => _recalculateThisAccount(context),
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
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: FMPrimaryButton(
                label: isEditing ? 'Save Changes' : 'Create Account',
                onPressed: formState.isValid
                    ? () async {
                        if (isEditing) {
                          // Update existing account
                          final originalAccount = ref.read(
                            accountByIdProvider(formState.editingAccountId!),
                          );
                          if (originalAccount != null) {
                            // Calculate new balance based on initial balance change
                            final initialBalanceDiff = formState.initialBalance - originalAccount.initialBalance;
                            final newBalance = originalAccount.balance + initialBalanceDiff;

                            final updatedAccount = originalAccount.copyWith(
                              name: formState.name,
                              type: formState.type,
                              initialBalance: formState.initialBalance,
                              balance: newBalance,
                            );
                            await ref.read(accountsProvider.notifier)
                                .updateAccount(updatedAccount);
                          }
                        } else {
                          // Add new account
                          await ref.read(accountsProvider.notifier).addAccount(
                                name: formState.name,
                                type: formState.type!,
                                initialBalance: formState.initialBalance,
                              );
                        }
                        ref.read(accountFormProvider.notifier).reset();
                        if (context.mounted) {
                          context.pop();
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final formState = ref.read(accountFormProvider);
    if (formState.editingAccountId == null) return;

    final account = ref.read(accountByIdProvider(formState.editingAccountId!));
    if (account == null) return;

    final transactionCount = ref.read(transactionCountByAccountProvider(account.id));

    if (transactionCount > 0) {
      // Show dialog with options
      final action = await showDeleteAccountDialog(
        context: context,
        account: account,
        transactionCount: transactionCount,
      );

      if (action == null || action == DeleteAccountAction.cancel) return;

      if (action == DeleteAccountAction.moveTransactions) {
        // Show account picker
        final accountsAsync = ref.read(accountsProvider);
        final accounts = accountsAsync.valueOrNull ?? [];
        final availableAccounts = accounts.where((a) => a.id != account.id).toList();

        if (availableAccounts.isEmpty) {
          // Can't move, show error
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No other accounts available to move transactions to',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
                backgroundColor: AppColors.surface,
              ),
            );
          }
          return;
        }

        if (!context.mounted) return;

        final targetAccount = await showMoveTransactionsDialog(
          context: context,
          sourceAccount: account,
          availableAccounts: availableAccounts,
        );

        if (targetAccount == null) return;

        // Move transactions then delete account
        await ref.read(transactionsProvider.notifier)
            .moveTransactionsToAccount(account.id, targetAccount.id);
        await ref.read(accountsProvider.notifier).deleteAccount(account.id);
      } else if (action == DeleteAccountAction.deleteWithTransactions) {
        // Delete all transactions then delete account
        await ref.read(transactionsProvider.notifier)
            .deleteTransactionsForAccount(account.id);
        await ref.read(accountsProvider.notifier).deleteAccount(account.id);
      }
    } else {
      // No transactions, show simple confirmation
      final confirmed = await showSimpleDeleteAccountDialog(
        context: context,
        account: account,
      );

      if (confirmed == true) {
        await ref.read(accountsProvider.notifier).deleteAccount(account.id);
      } else {
        return;
      }
    }

    ref.read(accountFormProvider.notifier).reset();
    if (context.mounted) {
      context.pop();
    }
  }

  Future<void> _recalculateThisAccount(BuildContext context) async {
    final formState = ref.read(accountFormProvider);
    if (formState.editingAccountId == null) return;

    final account = ref.read(accountByIdProvider(formState.editingAccountId!));
    if (account == null) return;

    // Get all transactions for this account
    final transactionsAsync = ref.read(transactionsProvider);
    final transactions = transactionsAsync.valueOrNull ?? [];
    final accountTransactions = transactions.where((t) => t.accountId == account.id);

    // Calculate transaction delta
    double transactionDelta = 0;
    for (final tx in accountTransactions) {
      transactionDelta += tx.type.name == 'income' ? tx.amount : -tx.amount;
    }

    // Calculate what the balance should be
    final expectedBalance = formState.initialBalance + transactionDelta;
    final currentBalance = formState.currentBalance;
    final difference = expectedBalance - currentBalance;

    if (difference.abs() < 0.001) {
      // No change needed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Balance is already correct',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Recalculate Balance?', style: AppTypography.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Based on initial balance and transaction history:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBalanceRow('Current', currentBalance),
            const SizedBox(height: AppSpacing.xs),
            _buildBalanceRow('Calculated', expectedBalance),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  'Difference: ',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  '${difference > 0 ? '+' : ''}\$${difference.toStringAsFixed(2)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: difference > 0 ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
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
              'Apply',
              style: AppTypography.button.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update the account balance
      final updatedAccount = account.copyWith(balance: expectedBalance);
      await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);

      // Update the form state to reflect the new balance
      ref.read(accountFormProvider.notifier).setCurrentBalance(expectedBalance);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Balance updated'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    }
  }

  Widget _buildBalanceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AccountTypeGrid extends ConsumerWidget {
  final AccountType? selectedType;
  final ValueChanged<AccountType> onChanged;

  const _AccountTypeGrid({
    this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.1,
      children: AccountType.values.map((type) {
        final isSelected = type == selectedType;
        final typeColor = AppColors.getAccountColor(type.name, intensity);
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            decoration: BoxDecoration(
              color: isSelected
                  ? typeColor.withOpacity(bgOpacity)
                  : AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: isSelected ? typeColor : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type.icon,
                  color: isSelected ? typeColor : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  type.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? typeColor : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
