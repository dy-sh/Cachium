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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController();

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
    super.dispose();
  }

  void _initializeForEdit() {
    if (_initialized || widget.accountId == null) return;

    final account = ref.read(accountByIdProvider(widget.accountId!));
    if (account != null) {
      ref.read(accountFormProvider.notifier).initForEdit(account);
      _nameController.text = account.name;
      _balanceController.text = account.balance.toString();
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
                      // When editing, show balance as read-only
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
                                  '\$${formState.initialBalance.toStringAsFixed(2)}',
                                  style: AppTypography.moneyMedium,
                                ),
                                const Spacer(),
                                Text(
                                  'Managed by transactions',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                            final updatedAccount = originalAccount.copyWith(
                              name: formState.name,
                              type: formState.type,
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
