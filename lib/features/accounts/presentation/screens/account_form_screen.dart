import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../providers/account_form_provider.dart';
import '../providers/accounts_provider.dart';
import '../widgets/account_appearance_section.dart';
import '../widgets/account_balance_section.dart';
import '../widgets/account_type_section.dart';
import '../widgets/delete_account_dialog.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final String? accountId;
  /// When true, pops with the new account ID after creation.
  final bool pickerMode;

  const AccountFormScreen({super.key, this.accountId, this.pickerMode = false});

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.accountId == null) {
        ref.read(accountFormProvider.notifier).reset();
      } else {
        _initializeForEdit();
        if (mounted) setState(() {});
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
    final formState = ref.watch(accountFormProvider);
    final isEditing = formState.isEditing;
    final accountName = formState.name.trim();

    final isDuplicateName = accountName.isNotEmpty && ref.watch(
      accountNameExistsProvider((name: accountName, excludeId: formState.editingAccountId)),
    );

    return UnsavedWorkPopScope(
      hasUnsavedWork: _hasUnsavedWork(formState),
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditing ? 'Edit Account' : 'New Account',
              onClose: () => context.pop(),
              trailing: isEditing
                  ? IconBtn(
                      icon: LucideIcons.trash2,
                      onPressed: () => _showDeleteConfirmation(context),
                      iconColor: AppColors.expense,
                      backgroundColor: AppColors.expense.withValues(alpha: 0.1),
                      size: 36,
                    )
                  : null,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputField(
                      key: ValueKey('name_${formState.editingAccountId}'),
                      label: 'Account Name',
                      hint: 'Enter account name...',
                      controller: _nameController,
                      autofocus: !isEditing,
                      onChanged: (value) {
                        ref.read(accountFormProvider.notifier).setName(value);
                      },
                      errorText: isDuplicateName ? 'Account with this name already exists' : null,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    AccountTypeSection(formState: formState),
                    const SizedBox(height: AppSpacing.xxl),

                    AccountBalanceSection(
                      formState: formState,
                      isEditing: isEditing,
                      balanceController: _balanceController,
                      initialBalanceController: _initialBalanceController,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Color picker
                    AccountAppearanceSection(formState: formState),
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
              child: PrimaryButton(
                label: isEditing ? 'Save Changes' : 'Create Account',
                isLoading: formState.isSaving,
                onPressed: formState.isValid &&
                        !isDuplicateName &&
                        !formState.isSaving
                    ? () => _saveAccount(formState)
                    : null,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  bool _hasUnsavedWork(AccountFormState formState) {
    if (formState.isEditing) return true; // edits always count
    return formState.name.isNotEmpty || formState.type != null;
  }

  Future<void> _saveAccount(AccountFormState formState) async {
    // Resolve the selected custom color from the current intensity palette.
    final intensity = ref.read(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);
    final customColor = formState.customColorIndex != null
        ? accentColors[
            formState.customColorIndex!.clamp(0, accentColors.length - 1)]
        : null;

    final result = await ref
        .read(accountFormProvider.notifier)
        .save(customColor: customColor);

    if (!mounted) return;
    if (!result.success) {
      context.showErrorNotification(result.errorMessage ?? 'Failed to save');
      return;
    }
    ref.read(accountFormProvider.notifier).reset();
    if (!mounted) return;
    if (!formState.isEditing && widget.pickerMode) {
      context.pop(result.newAccountId);
    } else {
      context.pop();
    }
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
        final accounts = accountsAsync.valueOrEmpty;
        final availableAccounts = accounts.where((a) => a.id != account.id).toList();

        if (availableAccounts.isEmpty) {
          // Can't move, show error
          if (context.mounted) {
            context.showWarningNotification(
              'No other accounts available to move transactions to',
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

        // Move transactions then delete account (atomic operation)
        await ref.read(accountsProvider.notifier)
            .deleteAccountMovingTransactions(account.id, targetAccount.id);
        // Refresh transactions provider
        ref.invalidate(transactionsProvider);
      } else if (action == DeleteAccountAction.deleteWithTransactions) {
        // Delete all transactions then delete account (atomic operation)
        await ref.read(accountsProvider.notifier)
            .deleteAccountWithTransactions(account.id);
        // Refresh transactions provider
        ref.invalidate(transactionsProvider);
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
