import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/database_management_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/color_picker_grid.dart';
import '../../../settings/presentation/widgets/recalculate_preview_dialog.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/account.dart';
import '../providers/account_form_provider.dart';
import '../providers/accounts_provider.dart';
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
    final accountName = formState.name.trim();

    final isDuplicateName = accountName.isNotEmpty && ref.watch(
      accountNameExistsProvider((name: accountName, excludeId: formState.editingAccountId)),
    );

    return PopScope(
      canPop: !_hasUnsavedWork(formState),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await showConfirmationDialog(
          context: context,
          title: 'Discard changes?',
          message: 'You have unsaved changes. Are you sure you want to go back?',
          confirmLabel: 'Discard',
          cancelLabel: 'Keep Editing',
          isDestructive: true,
        );
        if (shouldDiscard && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditing ? 'Edit Account' : 'New Account',
              onClose: () => context.pop(),
              trailing: isEditing
                  ? GestureDetector(
                      onTap: () => _showDeleteConfirmation(context),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.1),
                          borderRadius: AppRadius.smAll,
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

                    Text('Account Type', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.md),
                    Builder(
                      builder: (context) {
                        // Calculate custom color for the type grid
                        final intensity = ref.watch(colorIntensityProvider);
                        final accentColors = AppColors.getAccentOptions(intensity);
                        Color? customColor;
                        if (formState.customColorIndex != null) {
                          customColor = accentColors[formState.customColorIndex!.clamp(0, accentColors.length - 1)];
                        }
                        return _AccountTypeGrid(
                          selectedType: formState.type,
                          customColor: customColor,
                          onChanged: (type) {
                            ref.read(accountFormProvider.notifier).setType(type);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Currency selector
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
                        controller: _balanceController,
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
                      // Initial balance (editable in edit mode)
                      Builder(builder: (context) {
                        final symbol = Currency.symbolFromCode(formState.currencyCode);
                        return InputField(
                        key: ValueKey('initial_balance_${formState.editingAccountId}'),
                        label: 'Initial Balance',
                        hint: '0.00',
                        controller: _initialBalanceController,
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

                      // Current balance info note
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

                      // Hint about recalculation
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
                    const SizedBox(height: AppSpacing.xxl),

                    // Color picker
                    _buildColorPicker(ref, formState),
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
                onPressed: formState.isValid && !isDuplicateName
                    ? () async {
                        try {
                          // Get custom color if set
                          final intensity = ref.read(colorIntensityProvider);
                          final accentColors = AppColors.getAccentOptions(intensity);
                          final customColor = formState.customColorIndex != null
                              ? accentColors[formState.customColorIndex!.clamp(0, accentColors.length - 1)]
                              : null;

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
                                currencyCode: formState.currencyCode,
                                customColor: customColor,
                              );
                              await ref.read(accountsProvider.notifier)
                                  .updateAccount(updatedAccount);
                            }
                          } else {
                            // Add new account
                            final newAccountId = await ref.read(accountsProvider.notifier).addAccount(
                                  name: formState.name,
                                  type: formState.type!,
                                  initialBalance: formState.initialBalance,
                                  currencyCode: formState.currencyCode,
                                  customColor: customColor,
                                );
                            ref.read(accountFormProvider.notifier).reset();
                            if (context.mounted) {
                              // In picker mode, return the new account ID
                              if (widget.pickerMode) {
                                context.pop(newAccountId);
                              } else {
                                context.pop();
                              }
                            }
                            return;
                          }
                          ref.read(accountFormProvider.notifier).reset();
                          if (context.mounted) {
                            context.pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.showErrorNotification('Failed to save account: ${e.toString()}');
                          }
                        }
                      }
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

  Future<void> _recalculateThisAccount(BuildContext context) async {
    final formState = ref.read(accountFormProvider);
    if (formState.editingAccountId == null) return;

    final account = ref.read(accountByIdProvider(formState.editingAccountId!));
    if (account == null) return;

    // Get all transactions for this account (source or destination)
    final transactionsAsync = ref.read(transactionsProvider);
    final transactions = transactionsAsync.valueOrEmpty;
    final accountTransactions = transactions.where(
      (t) => t.accountId == account.id || t.destinationAccountId == account.id,
    );

    // Calculate transaction delta
    double transactionDelta = 0;
    for (final tx in accountTransactions) {
      if (tx.type == TransactionType.transfer) {
        // Transfers: subtract from source, add to destination
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

    // Calculate what the balance should be
    final expectedBalance = formState.initialBalance + transactionDelta;

    // Create a single-account preview using the same model as database settings
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

    // Show the same preview dialog as database settings
    final shouldApply = await showRecalculatePreviewDialog(
      context: context,
      preview: preview,
    );

    if (shouldApply == true && context.mounted) {
      // Update the account balance
      final updatedAccount = account.copyWith(balance: expectedBalance);
      await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);

      // Update the form state to reflect the new transaction delta
      ref.read(accountFormProvider.notifier).setTransactionDelta(transactionDelta);

      if (context.mounted) {
        context.showSuccessNotification('Balance updated');
      }
    }
  }

  Widget _buildColorPicker(WidgetRef ref, AccountFormState formState) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);

    // Get the default type color if available
    final defaultColor = formState.type != null
        ? AppColors.getAccountColor(formState.type!.name, intensity)
        : null;

    // Determine selected color:
    // 1. If user has selected a custom color index in this session, use that
    // 2. If editing and account has original custom color, try to find it in palette
    // 3. Otherwise use default type color
    Color? selectedColor;
    bool hasCustomColor = formState.hasCustomColor;

    if (formState.customColorIndex != null) {
      selectedColor = accentColors[formState.customColorIndex!.clamp(0, accentColors.length - 1)];
    } else if (formState.originalCustomColor != null) {
      // Try to find the original color in the palette
      final originalColorIndex = accentColors.indexWhere(
        (c) => c.toARGB32() == formState.originalCustomColor!.toARGB32(),
      );
      if (originalColorIndex != -1) {
        selectedColor = accentColors[originalColorIndex];
        hasCustomColor = true;
      } else {
        selectedColor = defaultColor;
      }
    } else {
      selectedColor = defaultColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Color', style: AppTypography.labelMedium),
            if (hasCustomColor || formState.originalCustomColor != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ref.read(accountFormProvider.notifier).setCustomColorIndex(null);
                },
                child: Text(
                  'Reset to default',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ColorPickerGrid(
          colors: accentColors,
          selectedColor: selectedColor ?? accentColors[0],
          crossAxisCount: 8,
          itemSize: 36,
          onColorSelected: (color) {
            final index = accentColors.indexOf(color);
            if (index != -1) {
              ref.read(accountFormProvider.notifier).setCustomColorIndex(index);
            }
          },
        ),
      ],
    );
  }
}

class _AccountTypeGrid extends ConsumerWidget {
  final AccountType? selectedType;
  final ValueChanged<AccountType> onChanged;
  final Color? customColor;

  const _AccountTypeGrid({
    this.selectedType,
    required this.onChanged,
    this.customColor,
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
      childAspectRatio: 2.2,
      children: AccountType.values.map((type) {
        final isSelected = type == selectedType;
        final defaultTypeColor = AppColors.getAccountColor(type.name, intensity);
        // Use custom color for selected type, otherwise use default type color
        final displayColor = isSelected && customColor != null
            ? customColor!
            : defaultTypeColor;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            decoration: BoxDecoration(
              color: isSelected
                  ? displayColor.withValues(alpha: bgOpacity)
                  : AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: isSelected ? displayColor : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type.icon,
                  color: isSelected ? displayColor : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  type.displayName,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? displayColor : AppColors.textSecondary,
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
