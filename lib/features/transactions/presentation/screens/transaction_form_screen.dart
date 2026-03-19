import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../../design_system/components/chips/toggle_chip.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../accounts/presentation/screens/account_form_screen.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transaction_templates_provider.dart';
import '../providers/transactions_provider.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../assets/presentation/widgets/asset_form_modal.dart';
import '../widgets/category_picker_form_screen.dart';
import '../widgets/date_selector.dart';
import '../widgets/merchant_autocomplete.dart';
import 'amount_section.dart';
import 'category_account_section.dart';
import 'transfer_section.dart';

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
  bool _isSaving = false;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureInitialized();
  }

  void _ensureInitialized() {
    if (_initialized) return;

    if (widget.transactionId != null) {
      // Edit mode
      final transaction = ref.read(transactionByIdProvider(widget.transactionId!));
      if (transaction != null) {
        ref.read(transactionFormProvider.notifier).initForEdit(transaction);
        _noteController.text = transaction.note ?? '';
        _merchantController.text = transaction.merchant ?? '';
        _initialized = true;
      }
    } else if (widget.initialType != null) {
      // New transaction with specific type
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
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eagerly load exchange rates so they're available when saving
    ref.watch(exchangeRatesProvider);

    final formState = ref.watch(transactionFormProvider);
    final selectLastAccount = ref.watch(selectLastAccountProvider);
    final recentAccountIds = ref.watch(recentlyUsedAccountIdsProvider);

    // Apply last used account when form has no account selected
    if (!_accountApplied &&
        !formState.isEditing &&
        formState.accountId == null &&
        selectLastAccount) {
      final lastUsedAccountId = ref.watch(lastUsedAccountIdProvider);
      final accountToSelect = lastUsedAccountId ??
          (recentAccountIds.isNotEmpty ? recentAccountIds.first : null);
      if (accountToSelect != null) {
        _accountApplied = true;
        Future.microtask(() {
          if (mounted) {
            ref.read(transactionFormProvider.notifier).setAccount(accountToSelect);
          }
        });
      }
    }

    final isEditing = formState.isEditing;

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
              title: isEditing ? 'Edit Transaction' : 'New Transaction',
              onClose: () => context.pop(),
              trailing: isEditing
                  ? GestureDetector(
                      onTap: () => _deleteAndShowUndo(context),
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
                  : GestureDetector(
                      onTap: () => _showTemplatePicker(context),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.smAll,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          LucideIcons.fileText,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),

            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TransactionTypeSelector(formState: formState),
                    const SizedBox(height: AppSpacing.xxl),
                    AmountSection(
                      formState: formState,
                      isEditing: isEditing,
                      onAmountChanged: (amount) {
                        ref.read(transactionFormProvider.notifier).setAmount(amount);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (!formState.isTransfer) ...[
                      CategorySection(
                        formState: formState,
                        onCategoryChanged: (id) {
                          if (id != null) {
                            ref.read(transactionFormProvider.notifier).setCategory(id);
                          }
                        },
                        onCreateCategory: (parentId) {
                          _createNewCategory(context, ref, formState.type, parentId);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AssetSection(
                        formState: formState,
                        onAssetChanged: (id) {
                          ref.read(transactionFormProvider.notifier).setAsset(id);
                        },
                        onCreateAsset: () {
                          _createNewAsset(context, ref);
                        },
                        onClearAsset: () {
                          ref.read(transactionFormProvider.notifier).clearAsset();
                        },
                      ),
                    ],
                    AccountSection(
                      formState: formState,
                      onAccountChanged: (id) {
                        if (id != null) {
                          ref.read(transactionFormProvider.notifier).setAccount(id);
                        }
                      },
                      onCreateAccount: () {
                        _createNewAccount(context, ref);
                      },
                    ),
                    if (formState.isTransfer)
                      TransferSection(
                        formState: formState,
                        onDestinationAccountChanged: (id) {
                          ref.read(transactionFormProvider.notifier).setDestinationAccount(id);
                        },
                        onDestinationAmountChanged: (amount) {
                          ref.read(transactionFormProvider.notifier).setDestinationAmount(amount);
                        },
                        onCreateAccount: () {
                          _createNewAccount(context, ref);
                        },
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                    DateSelector(
                      date: formState.date,
                      onChanged: (date) {
                        ref.read(transactionFormProvider.notifier).setDate(date);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    MerchantAutocomplete(
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

            _SaveBar(
              formState: formState,
              isSaving: _isSaving,
              onSave: () => _saveTransaction(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Returns true when the user has made meaningful changes worth confirming discard.
  bool _hasUnsavedWork(TransactionFormState formState) {
    if (formState.isEditing) return formState.hasChanges;
    return formState.amount > 0 ||
        (formState.note != null && formState.note!.isNotEmpty) ||
        (formState.merchant != null && formState.merchant!.isNotEmpty);
  }

  Future<void> _saveTransaction() async {
    setState(() => _isSaving = true);
    try {
      final result = await ref.read(transactionFormProvider.notifier).save();
      if (mounted) {
        if (result.success) {
          context.pop();
          context.showSuccessNotification(result.message);
        } else {
          context.showErrorNotification(result.message);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAndShowUndo(BuildContext context) async {
    final formState = ref.read(transactionFormProvider);
    if (formState.editingTransactionId == null) return;

    // Capture the full transaction before deleting
    final tx = ref.read(transactionByIdProvider(formState.editingTransactionId!));
    if (tx == null) return;

    final shouldDelete = await showConfirmationDialog(
      context: context,
      title: 'Delete transaction?',
      message: 'This transaction will be deleted. You can undo this action briefly after.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (!shouldDelete) return;

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
        builder: (context) => CategoryPickerFormScreen(
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

  Future<void> _createNewAsset(BuildContext context, WidgetRef ref) async {
    final newAssetId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => AssetFormModal(
          onSave: (name, icon, colorIndex, status, note) async {
            final id = await ref.read(assetsProvider.notifier).addAsset(
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              note: note,
            );
            if (context.mounted) {
              Navigator.of(context).pop(id);
            }
          },
        ),
      ),
    );

    if (newAssetId != null && mounted) {
      ref.read(transactionFormProvider.notifier).setAsset(newAssetId);
    }
  }

  void _showTemplatePicker(BuildContext context) {
    final templates =
        ref.read(transactionTemplatesProvider).valueOrNull ?? [];
    if (templates.isEmpty) {
      context.showInfoNotification('No templates yet. Create one in Settings.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: Text('Apply Template', style: AppTypography.h4),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (_, index) {
                    final template = templates[index];
                    final typeColor = AppColors.getTransactionColor(
                      template.type.name,
                      ref.read(colorIntensityProvider),
                    );
                    final subtitleParts = <String>[template.type.displayName];
                    if (template.amount != null) {
                      subtitleParts.add(template.amount!.toStringAsFixed(2));
                    }
                    if (template.merchant != null) {
                      subtitleParts.add(template.merchant!);
                    }
                    return ListTile(
                      leading: Icon(
                        LucideIcons.fileText,
                        color: typeColor,
                        size: 20,
                      ),
                      title: Text(
                        template.name,
                        style: AppTypography.bodyMedium,
                      ),
                      subtitle: Text(
                        subtitleParts.join(' \u00b7 '),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        ref.read(transactionFormProvider.notifier)
                            .applyTemplate(template);
                        // Update text controllers
                        if (template.merchant != null) {
                          _merchantController.text = template.merchant!;
                        }
                        if (template.note != null) {
                          _noteController.text = template.note!;
                        }
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

// --- Extracted sub-section widgets ---

class _TransactionTypeSelector extends ConsumerWidget {
  final TransactionFormState formState;

  const _TransactionTypeSelector({required this.formState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final isIncome = formState.type == TransactionType.income;
    final isTransfer = formState.isTransfer;

    return Center(
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
    );
  }
}

class _SaveBar extends StatelessWidget {
  final TransactionFormState formState;
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveBar({
    required this.formState,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = formState.isEditing;
    return ClipRect(
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
            onPressed: !isSaving ? onSave : null,
          ),
        ),
      ),
    );
  }
}
