import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/fm_primary_button.dart';
import '../../../../design_system/components/layout/fm_form_header.dart';
import '../../../../design_system/components/chips/fm_toggle_chip.dart';
import '../../../../design_system/components/inputs/fm_amount_input.dart';
import '../../../../design_system/components/inputs/fm_text_field.dart';
import '../../../../navigation/app_router.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_selector.dart';
import '../widgets/date_selector.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const TransactionFormScreen({super.key, this.transactionId});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  bool _initialized = false;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _initializeForEdit() {
    if (_initialized || widget.transactionId == null) return;

    final transaction = ref.read(transactionByIdProvider(widget.transactionId!));
    if (transaction != null) {
      ref.read(transactionFormProvider.notifier).initForEdit(transaction);
      _noteController.text = transaction.note ?? '';
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize for edit mode after the first frame
    if (widget.transactionId != null && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeForEdit();
        if (mounted) setState(() {});
      });
    }

    final formState = ref.watch(transactionFormProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrEmpty;
    final intensity = ref.watch(colorIntensityProvider);

    final categories = formState.type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    final isIncome = formState.type == TransactionType.income;
    final isEditing = formState.isEditing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FMFormHeader(
              title: isEditing ? 'Edit Transaction' : 'New Transaction',
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
                    Center(
                      child: FMToggleChip(
                        options: const ['Expense', 'Income'],
                        selectedIndex: isIncome ? 1 : 0,
                        colors: [
                          AppColors.getTransactionColor('expense', intensity),
                          AppColors.getTransactionColor('income', intensity),
                        ],
                        onChanged: (index) {
                          ref.read(transactionFormProvider.notifier).setType(
                                index == 1 ? TransactionType.income : TransactionType.expense,
                              );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    FMAmountInput(
                      key: ValueKey('amount_${formState.editingTransactionId}'),
                      initialValue: formState.amount > 0 ? formState.amount : null,
                      transactionType: formState.type.name,
                      autofocus: !isEditing,
                      onChanged: (amount) {
                        ref.read(transactionFormProvider.notifier).setAmount(amount);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text('Category', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    CategorySelector(
                      categories: categories,
                      selectedId: formState.categoryId,
                      onChanged: (id) {
                        ref.read(transactionFormProvider.notifier).setCategory(id);
                      },
                      onCreatePressed: () => context.push(AppRoutes.categoryManagement),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text('Account', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    AccountSelector(
                      accounts: accounts,
                      selectedId: formState.accountId,
                      onChanged: (id) {
                        ref.read(transactionFormProvider.notifier).setAccount(id);
                      },
                      onCreatePressed: () => context.push(AppRoutes.accountForm),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    DateSelector(
                      date: formState.date,
                      onChanged: (date) {
                        ref.read(transactionFormProvider.notifier).setDate(date);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    FMTextField(
                      key: ValueKey('note_${formState.editingTransactionId}'),
                      label: 'Note (optional)',
                      hint: 'Add a note...',
                      controller: _noteController,
                      onChanged: (value) {
                        ref.read(transactionFormProvider.notifier).setNote(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.8),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: AppSpacing.screenPadding,
                    right: AppSpacing.screenPadding,
                    top: AppSpacing.md,
                    bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                  ),
                  child: FMPrimaryButton(
                    label: isEditing ? 'Save Changes' : 'Save Transaction',
                    onPressed: formState.canSave
                        ? () async {
                            // Save last used account
                            ref.read(settingsProvider.notifier).setLastUsedAccountId(formState.accountId);

                            if (isEditing) {
                              // Update existing transaction
                              final originalTransaction = ref.read(
                                transactionByIdProvider(formState.editingTransactionId!),
                              );
                              if (originalTransaction != null) {
                                final updatedTransaction = originalTransaction.copyWith(
                                  amount: formState.amount,
                                  type: formState.type,
                                  categoryId: formState.categoryId,
                                  accountId: formState.accountId,
                                  date: formState.date,
                                  note: formState.note,
                                );
                                await ref.read(transactionsProvider.notifier)
                                    .updateTransaction(updatedTransaction);
                              }
                            } else {
                              // Add new transaction
                              await ref.read(transactionsProvider.notifier).addTransaction(
                                    amount: formState.amount,
                                    type: formState.type,
                                    categoryId: formState.categoryId!,
                                    accountId: formState.accountId!,
                                    date: formState.date,
                                    note: formState.note,
                                  );
                            }
                            if (context.mounted) {
                              context.pop();
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Transaction',
          style: AppTypography.h4,
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final formState = ref.read(transactionFormProvider);
              if (formState.editingTransactionId != null) {
                await ref.read(transactionsProvider.notifier)
                    .deleteTransaction(formState.editingTransactionId!);
                if (mounted && parentContext.mounted) {
                  parentContext.pop();
                }
              }
            },
            child: Text(
              'Delete',
              style: AppTypography.button.copyWith(
                color: AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
