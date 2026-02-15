import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../../design_system/components/chips/toggle_chip.dart';
import '../../../../design_system/components/inputs/amount_input.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../accounts/presentation/screens/account_form_screen.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/category_form_modal.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_selector.dart';
import '../widgets/date_selector.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? initialType;

  const TransactionFormScreen({super.key, this.transactionId, this.initialType});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  bool _initialized = false;
  bool _accountApplied = false;
  late TextEditingController _noteController;
  late TextEditingController _merchantController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _merchantController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _initializeForEdit() {
    if (_initialized || widget.transactionId == null) return;

    final transaction = ref.read(transactionByIdProvider(widget.transactionId!));
    if (transaction != null) {
      ref.read(transactionFormProvider.notifier).initForEdit(transaction);
      _noteController.text = transaction.note ?? '';
      _merchantController.text = transaction.merchant ?? '';
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

    // Initialize form with initial type if provided
    if (widget.initialType != null && !_initialized && widget.transactionId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final TransactionType type;
        switch (widget.initialType) {
          case 'income':
            type = TransactionType.income;
          case 'transfer':
            type = TransactionType.transfer;
          default:
            type = TransactionType.expense;
        }
        ref.read(transactionFormProvider.notifier).reset();
        ref.read(transactionFormProvider.notifier).setType(type);
        ref.read(transactionFormProvider.notifier).applyLastUsedAccountIfNeeded();
        if (mounted) setState(() {});
        _initialized = true;
      });
    }

    final formState = ref.watch(transactionFormProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrEmpty;
    final recentAccountIds = ref.watch(recentlyUsedAccountIdsProvider);
    final selectLastAccount = ref.watch(selectLastAccountProvider);

    // Apply last used account when form has no account selected
    // Use lastUsedAccountId from settings, or fall back to first recent account
    if (!_accountApplied &&
        !formState.isEditing &&
        formState.accountId == null &&
        selectLastAccount) {
      final lastUsedAccountId = ref.watch(lastUsedAccountIdProvider);
      // Use lastUsedAccountId if available, otherwise use first recent account
      final accountToSelect = lastUsedAccountId ??
          (recentAccountIds.isNotEmpty ? recentAccountIds.first : null);
      if (accountToSelect != null) {
        _accountApplied = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(transactionFormProvider.notifier).setAccount(accountToSelect);
          }
        });
      }
    }
    final intensity = ref.watch(colorIntensityProvider);

    // Transaction settings
    final accountsFoldedCount = ref.watch(accountsFoldedCountProvider);
    final categoriesFoldedCount = ref.watch(categoriesFoldedCountProvider);
    final showAddAccountButton = ref.watch(showAddAccountButtonProvider);
    final showAddCategoryButton = ref.watch(showAddCategoryButtonProvider);
    final categorySortOption = ref.watch(categorySortOptionProvider);
    final allowSelectParentCategory = ref.watch(allowSelectParentCategoryProvider);

    final isTransfer = formState.type == TransactionType.transfer;

    final categories = formState.type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    // Get recently used category IDs for current transaction type
    final categoryType = formState.type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final recentCategoryIds = ref.watch(recentlyUsedCategoryIdsProvider(categoryType));

    final isIncome = formState.type == TransactionType.income;
    final isEditing = formState.isEditing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditing ? 'Edit Transaction' : 'New Transaction',
              onClose: () => context.pop(),
              trailing: isEditing
                  ? GestureDetector(
                      onTap: () => _deleteAndShowUndo(context),
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
                      child: ToggleChip(
                        options: const ['Income', 'Expense', 'Transfer'],
                        selectedIndex: isIncome ? 0 : (isTransfer ? 2 : 1),
                        colors: [
                          AppColors.getTransactionColor('income', intensity),
                          AppColors.getTransactionColor('expense', intensity),
                          AppColors.getTransactionColor('transfer', intensity),
                        ],
                        onChanged: (index) {
                          final type = switch (index) {
                            0 => TransactionType.income,
                            2 => TransactionType.transfer,
                            _ => TransactionType.expense,
                          };
                          ref.read(transactionFormProvider.notifier).setType(type);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    AmountInput(
                      key: ValueKey('amount_${formState.editingTransactionId}'),
                      initialValue: formState.amount > 0 ? formState.amount : null,
                      transactionType: formState.type.name,
                      autofocus: !isEditing,
                      onChanged: (amount) {
                        ref.read(transactionFormProvider.notifier).setAmount(amount);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (!isTransfer) ...[
                      Text('Category', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      CategorySelector(
                        categories: categories,
                        selectedId: formState.categoryId,
                        initialVisibleCount: categoriesFoldedCount,
                        sortOption: categorySortOption,
                        recentCategoryIds: recentCategoryIds,
                        allowSelectParentCategory: allowSelectParentCategory,
                        onChanged: (id) {
                          ref.read(transactionFormProvider.notifier).setCategory(id);
                        },
                        onCreatePressed: showAddCategoryButton
                            ? (parentId) => _createNewCategory(context, ref, formState.type, parentId)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    Text(isTransfer ? 'From Account' : 'Account', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    AccountSelector(
                      accounts: accounts,
                      selectedId: formState.accountId,
                      recentAccountIds: recentAccountIds,
                      initialVisibleCount: accountsFoldedCount,
                      excludeAccountId: isTransfer ? formState.destinationAccountId : null,
                      onChanged: (id) {
                        ref.read(transactionFormProvider.notifier).setAccount(id);
                      },
                      onCreatePressed: showAddAccountButton
                          ? () => _createNewAccount(context, ref)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (isTransfer) ...[
                      Text('To Account', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AccountSelector(
                        accounts: accounts,
                        selectedId: formState.destinationAccountId,
                        recentAccountIds: recentAccountIds,
                        initialVisibleCount: accountsFoldedCount,
                        excludeAccountId: formState.accountId,
                        onChanged: (id) {
                          ref.read(transactionFormProvider.notifier).setDestinationAccount(id);
                        },
                        onCreatePressed: showAddAccountButton
                            ? () => _createNewAccount(context, ref)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    DateSelector(
                      date: formState.date,
                      onChanged: (date) {
                        ref.read(transactionFormProvider.notifier).setDate(date);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    _MerchantAutocomplete(
                      key: ValueKey('merchant_${formState.editingTransactionId}'),
                      controller: _merchantController,
                      onChanged: (value) {
                        ref.read(transactionFormProvider.notifier).setMerchant(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    InputField(
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
                    color: AppColors.background.withValues(alpha: 0.8),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
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
                  child: PrimaryButton(
                    label: isEditing ? 'Save Changes' : 'Save Transaction',
                    onPressed: formState.canSave
                        ? () async {
                            // Save last used account and category
                            ref.read(settingsProvider.notifier).setLastUsedAccountId(formState.accountId);
                            if (!isTransfer) {
                              ref.read(settingsProvider.notifier).setLastUsedCategoryId(
                                formState.type,
                                formState.categoryId,
                              );
                            }

                            if (isEditing) {
                              // Update existing transaction
                              final originalTransaction = ref.read(
                                transactionByIdProvider(formState.editingTransactionId!),
                              );
                              if (originalTransaction != null) {
                                final updatedTransaction = originalTransaction.copyWith(
                                  amount: formState.amount,
                                  type: formState.type,
                                  categoryId: isTransfer ? '' : formState.categoryId,
                                  accountId: formState.accountId,
                                  destinationAccountId: formState.destinationAccountId,
                                  clearDestinationAccountId: !isTransfer,
                                  date: formState.date,
                                  note: formState.note,
                                  merchant: formState.merchant,
                                );
                                await ref.read(transactionsProvider.notifier)
                                    .updateTransaction(updatedTransaction);
                              }
                            } else {
                              // Add new transaction
                              await ref.read(transactionsProvider.notifier).addTransaction(
                                    amount: formState.amount,
                                    type: formState.type,
                                    categoryId: isTransfer ? '' : formState.categoryId!,
                                    accountId: formState.accountId!,
                                    destinationAccountId: formState.destinationAccountId,
                                    date: formState.date,
                                    note: formState.note,
                                    merchant: formState.merchant,
                                  );
                            }
                            if (context.mounted) {
                              context.pop();
                              context.showSuccessNotification(
                                isEditing ? 'Transaction updated' : 'Transaction saved',
                              );
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

  Future<void> _deleteAndShowUndo(BuildContext context) async {
    final formState = ref.read(transactionFormProvider);
    if (formState.editingTransactionId == null) return;

    // Capture the full transaction before deleting
    final tx = ref.read(transactionByIdProvider(formState.editingTransactionId!));
    if (tx == null) return;

    // Capture notifier before popping (ref won't be valid after dispose)
    final notifier = ref.read(transactionsProvider.notifier);

    await notifier.deleteTransaction(tx.id);

    if (mounted && context.mounted) {
      context.pop();
      context.showUndoNotification(
        'Transaction deleted',
        () => notifier.restoreTransaction(tx),
      );
    }
  }

  Future<void> _createNewCategory(
    BuildContext context,
    WidgetRef ref,
    TransactionType transactionType,
    String? parentId,
  ) async {
    final categoryType = transactionType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    final newCategoryId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => _CategoryPickerFormScreen(
          type: categoryType,
          initialParentId: parentId,
          onCategoryCreated: (id) => Navigator.of(context).pop(id),
        ),
      ),
    );

    if (newCategoryId != null && mounted) {
      ref.read(transactionFormProvider.notifier).setCategory(newCategoryId);
    }
  }

  Future<void> _createNewAccount(BuildContext context, WidgetRef ref) async {
    final newAccountId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const AccountFormScreen(pickerMode: true),
      ),
    );

    if (newAccountId != null && mounted) {
      ref.read(transactionFormProvider.notifier).setAccount(newAccountId);
    }
  }
}

class _MerchantAutocomplete extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _MerchantAutocomplete({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  ConsumerState<_MerchantAutocomplete> createState() => _MerchantAutocompleteState();
}

class _MerchantAutocompleteState extends ConsumerState<_MerchantAutocomplete> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchants = ref.watch(merchantSuggestionsProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Merchant (optional)',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable.empty();
            final query = textEditingValue.text.toLowerCase();
            return merchants
                .where((m) => m.toLowerCase().contains(query))
                .take(5);
          },
          onSelected: (selection) {
            widget.controller.text = selection;
            widget.onChanged(selection);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isFocused ? accentColor : AppColors.border,
                  width: _isFocused ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: widget.onChanged,
                style: AppTypography.input,
                cursorColor: accentColor,
                decoration: InputDecoration(
                  hintText: 'e.g. Amazon, Starbucks...',
                  hintStyle: AppTypography.inputHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.inputPadding,
                    vertical: AppSpacing.inputPadding,
                  ),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            border: index < options.length - 1
                                ? Border(
                                    bottom: BorderSide(
                                      color: AppColors.border.withValues(alpha: 0.5),
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.store,
                                size: 16,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                option,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A screen that wraps CategoryFormModal for picker mode.
class _CategoryPickerFormScreen extends ConsumerWidget {
  final CategoryType type;
  final String? initialParentId;
  final ValueChanged<String> onCategoryCreated;

  const _CategoryPickerFormScreen({
    required this.type,
    this.initialParentId,
    required this.onCategoryCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CategoryFormModal(
      type: type,
      initialParentId: initialParentId,
      onSave: (name, icon, colorIndex, parentId) async {
        final uuid = const Uuid();
        final newId = uuid.v4();

        final category = Category(
          id: newId,
          name: name,
          icon: icon,
          colorIndex: colorIndex,
          type: type,
          parentId: parentId,
          isCustom: true,
          sortOrder: 0,
        );

        await ref.read(categoriesProvider.notifier).addCategory(category);
        onCategoryCreated(newId);
      },
    );
  }
}
