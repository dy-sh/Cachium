import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
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
import '../../data/models/transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transaction_templates_provider.dart';
import '../providers/transactions_provider.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../assets/presentation/widgets/asset_form_modal.dart';
import '../../../assets/presentation/widgets/asset_selector.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_picker_form_screen.dart';
import '../widgets/category_selector.dart';
import '../widgets/date_selector.dart';
import '../widgets/merchant_autocomplete.dart';

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
                          borderRadius: BorderRadius.circular(8),
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
                          borderRadius: BorderRadius.circular(8),
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
                    _AmountSection(formState: formState, isEditing: isEditing),
                    const SizedBox(height: AppSpacing.xxl),
                    if (!formState.isTransfer) ...[
                      _CategorySection(formState: formState),
                      const SizedBox(height: AppSpacing.xxl),
                      _AssetSection(formState: formState),
                    ],
                    _AccountSection(formState: formState),
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

class _AmountSection extends ConsumerWidget {
  final TransactionFormState formState;
  final bool isEditing;

  const _AmountSection({required this.formState, required this.isEditing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);
    final isStale = ref.watch(exchangeRatesStaleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountInput(
          key: ValueKey('amount_${formState.editingTransactionId}_${formState.currencyCode}'),
          initialValue: formState.amount > 0 ? formState.amount : null,
          transactionType: formState.type.name,
          currencyCode: formState.currencyCode,
          autofocus: !isEditing,
          onChanged: (amount) {
            ref.read(transactionFormProvider.notifier).setAmount(amount);
          },
        ),
        if (formState.amountError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              formState.amountError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
            ),
          ),
        if (formState.currencyCode != mainCurrency && isStale)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 14, color: AppColors.yellow),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Exchange rates may be outdated',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.yellow),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final TransactionFormState formState;

  const _CategorySection({required this.formState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final categoriesFoldedCount = ref.watch(categoriesFoldedCountProvider);
    final showAddCategoryButton = ref.watch(showAddCategoryButtonProvider);
    final categorySortOption = ref.watch(categorySortOptionProvider);
    final allowSelectParentCategory = ref.watch(allowSelectParentCategoryProvider);

    final categories = formState.type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    final categoryType = formState.type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final recentCategoryIds = ref.watch(recentlyUsedCategoryIdsProvider(categoryType));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: AppTypography.labelMedium),
        if (formState.categoryError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              formState.categoryError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
            ),
          ),
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
              ? (parentId) {
                  final state = context.findAncestorStateOfType<_TransactionFormScreenState>();
                  state?._createNewCategory(context, ref, formState.type, parentId);
                }
              : null,
        ),
      ],
    );
  }
}

class _AssetSection extends ConsumerWidget {
  final TransactionFormState formState;

  const _AssetSection({required this.formState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final globalShowAssets = ref.watch(showAssetSelectorProvider);
    final categoryShowsAssets = ref.watch(categoryShowsAssetsProvider(formState.categoryId));
    final isTransfer = formState.isTransfer;
    final showAssets = !isTransfer && globalShowAssets && categoryShowsAssets;

    // Auto-clear asset when category changes to one that doesn't show assets
    // (skip for editing mode to preserve the linked asset for read-only display)
    if (!showAssets && formState.assetId != null && !formState.isEditing && !isTransfer) {
      Future.microtask(() {
        ref.read(transactionFormProvider.notifier).clearAsset();
      });
    }

    if (showAssets) {
      final activeAssets = ref.watch(activeAssetsProvider);
      final categoryAssets = ref.watch(assetsForCategoryProvider(formState.categoryId));
      final assetsFoldedCount = ref.watch(assetsFoldedCountProvider);
      final showAddAssetButton = ref.watch(showAddAssetButtonProvider);
      final assetSortOption = ref.watch(assetSortOptionProvider);
      final recentAssetIds = ref.watch(recentlyUsedAssetIdsProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asset (optional)', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          AssetSelector(
            assets: activeAssets,
            categoryAssets: categoryAssets,
            selectedId: formState.assetId,
            recentAssetIds: recentAssetIds,
            initialVisibleCount: assetsFoldedCount,
            sortOption: assetSortOption,
            onChanged: (id) {
              ref.read(transactionFormProvider.notifier).setAsset(id);
            },
            onCreatePressed: showAddAssetButton
                ? () {
                    final state = context.findAncestorStateOfType<_TransactionFormScreenState>();
                    state?._createNewAsset(context, ref);
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      );
    }

    // Show linked asset read-only when editing a tx that has an asset
    // but the category now has showAssets=false
    if (!isTransfer && globalShowAssets && formState.assetId != null && formState.isEditing) {
      final asset = ref.watch(assetByIdProvider(formState.assetId!));
      if (asset == null) return const SizedBox.shrink();
      final assetColor = asset.getColor(intensity);
      final bgOpacity = AppColors.getBgOpacity(intensity);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asset', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: assetColor.withValues(alpha: bgOpacity),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: assetColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(asset.icon, size: 14, color: assetColor),
                    const SizedBox(width: 4),
                    Text(
                      asset.name,
                      style: AppTypography.labelSmall.copyWith(color: assetColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () {
                  HapticHelper.lightImpact();
                  ref.read(transactionFormProvider.notifier).setAsset(null);
                },
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _AccountSection extends ConsumerWidget {
  final TransactionFormState formState;

  const _AccountSection({required this.formState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrEmpty;
    final recentAccountIds = ref.watch(recentlyUsedAccountIdsProvider);
    final accountsFoldedCount = ref.watch(accountsFoldedCountProvider);
    final showAddAccountButton = ref.watch(showAddAccountButtonProvider);
    final isTransfer = formState.isTransfer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isTransfer ? 'From Account' : 'Account', style: AppTypography.labelMedium),
        if (formState.accountError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              formState.accountError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
            ),
          ),
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
              ? () {
                  final state = context.findAncestorStateOfType<_TransactionFormScreenState>();
                  state?._createNewAccount(context, ref);
                }
              : null,
        ),
        if (isTransfer) ...[
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
            onChanged: (id) {
              ref.read(transactionFormProvider.notifier).setDestinationAccount(id);
            },
            onCreatePressed: showAddAccountButton
                ? () {
                    final state = context.findAncestorStateOfType<_TransactionFormScreenState>();
                    state?._createNewAccount(context, ref);
                  }
                : null,
          ),
          // Cross-currency destination amount
          if (formState.destinationAmount != null) _DestinationAmountInput(formState: formState),
        ],
      ],
    );
  }
}

class _DestinationAmountInput extends ConsumerWidget {
  final TransactionFormState formState;

  const _DestinationAmountInput({required this.formState});

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
          onChanged: (amount) {
            ref.read(transactionFormProvider.notifier).setDestinationAmount(amount);
          },
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
