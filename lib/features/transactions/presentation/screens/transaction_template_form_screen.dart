import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/chips/toggle_chip.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/inputs/amount_input.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_template.dart';
import '../providers/transaction_template_form_provider.dart';
import '../providers/transaction_templates_provider.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_selector.dart';

class TransactionTemplateFormScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const TransactionTemplateFormScreen({super.key, this.templateId});

  @override
  ConsumerState<TransactionTemplateFormScreen> createState() =>
      _TransactionTemplateFormScreenState();
}

class _TransactionTemplateFormScreenState
    extends ConsumerState<TransactionTemplateFormScreen> {
  bool _initialized = false;
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _merchantController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
    _merchantController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _initializeForEdit() {
    if (_initialized || widget.templateId == null) return;

    final templates =
        ref.read(transactionTemplatesProvider).valueOrNull ?? [];
    final template =
        templates.where((t) => t.id == widget.templateId).firstOrNull;
    if (template != null) {
      ref.read(transactionTemplateFormProvider.notifier).initForEdit(template);
      _nameController.text = template.name;
      _noteController.text = template.note ?? '';
      _merchantController.text = template.merchant ?? '';
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.templateId != null && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeForEdit();
        if (mounted) setState(() {});
      });
    }

    final formState = ref.watch(transactionTemplateFormProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrEmpty;
    final intensity = ref.watch(colorIntensityProvider);
    final categoriesFoldedCount = ref.watch(categoriesFoldedCountProvider);
    final accountsFoldedCount = ref.watch(accountsFoldedCountProvider);
    final categorySortOption = ref.watch(categorySortOptionProvider);
    final allowSelectParentCategory =
        ref.watch(allowSelectParentCategoryProvider);

    final isTransfer = formState.isTransfer;
    final isIncome = formState.type == TransactionType.income;
    final isEditing = formState.isEditing;

    final categories =
        formState.type == TransactionType.income
            ? incomeCategories
            : expenseCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditing ? 'Edit Template' : 'New Template',
              onClose: () => context.pop(),
              trailing: isEditing
                  ? GestureDetector(
                      onTap: () => _deleteTemplate(context),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputField(
                      key: ValueKey('name_${formState.editingTemplateId}'),
                      label: 'Template Name',
                      hint: 'e.g. Car Refueling, Monthly Rent...',
                      controller: _nameController,
                      autofocus: !isEditing,
                      onChanged: (value) {
                        ref
                            .read(transactionTemplateFormProvider.notifier)
                            .setName(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

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
                          ref
                              .read(transactionTemplateFormProvider.notifier)
                              .setType(type);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    AmountInput(
                      key: ValueKey('amount_${formState.editingTemplateId}'),
                      initialValue: formState.amount,
                      transactionType: formState.type.name,
                      onChanged: (amount) {
                        ref
                            .read(transactionTemplateFormProvider.notifier)
                            .setAmount(amount);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Amount is optional for templates',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (!isTransfer) ...[
                      Text('Category (optional)',
                          style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      CategorySelector(
                        categories: categories,
                        selectedId: formState.categoryId,
                        initialVisibleCount: categoriesFoldedCount,
                        sortOption: categorySortOption,
                        recentCategoryIds: const [],
                        allowSelectParentCategory: allowSelectParentCategory,
                        onChanged: (id) {
                          ref
                              .read(transactionTemplateFormProvider.notifier)
                              .setCategory(id);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    Text(isTransfer ? 'From Account (optional)' : 'Account (optional)',
                        style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    AccountSelector(
                      accounts: accounts,
                      selectedId: formState.accountId,
                      recentAccountIds: const [],
                      initialVisibleCount: accountsFoldedCount,
                      excludeAccountId:
                          isTransfer ? formState.destinationAccountId : null,
                      onChanged: (id) {
                        ref
                            .read(transactionTemplateFormProvider.notifier)
                            .setAccount(id);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (isTransfer) ...[
                      Text('To Account (optional)',
                          style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AccountSelector(
                        accounts: accounts,
                        selectedId: formState.destinationAccountId,
                        recentAccountIds: const [],
                        initialVisibleCount: accountsFoldedCount,
                        excludeAccountId: formState.accountId,
                        onChanged: (id) {
                          ref
                              .read(transactionTemplateFormProvider.notifier)
                              .setDestinationAccount(id);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    InputField(
                      key: ValueKey('merchant_${formState.editingTemplateId}'),
                      label: 'Merchant (optional)',
                      hint: 'e.g. Amazon, Starbucks...',
                      controller: _merchantController,
                      onChanged: (value) {
                        ref
                            .read(transactionTemplateFormProvider.notifier)
                            .setMerchant(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    InputField(
                      key: ValueKey('note_${formState.editingTemplateId}'),
                      label: 'Note (optional)',
                      hint: 'Add a note...',
                      controller: _noteController,
                      onChanged: (value) {
                        ref
                            .read(transactionTemplateFormProvider.notifier)
                            .setNote(value);
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
                    bottom:
                        MediaQuery.of(context).padding.bottom + AppSpacing.md,
                  ),
                  child: PrimaryButton(
                    label: isEditing ? 'Save Changes' : 'Save Template',
                    onPressed: formState.canSave
                        ? () async {
                            if (isEditing) {
                              final templates = ref
                                      .read(transactionTemplatesProvider)
                                      .valueOrNull ??
                                  [];
                              final original = templates
                                  .where((t) =>
                                      t.id == formState.editingTemplateId)
                                  .firstOrNull;
                              if (original != null) {
                                final updated = TransactionTemplate(
                                  id: original.id,
                                  name: formState.name.trim(),
                                  amount: formState.amount,
                                  type: formState.type,
                                  categoryId: isTransfer
                                      ? null
                                      : formState.categoryId,
                                  accountId: formState.accountId,
                                  destinationAccountId:
                                      formState.destinationAccountId,
                                  assetId: formState.assetId,
                                  merchant: formState.merchant,
                                  note: formState.note,
                                  createdAt: original.createdAt,
                                );
                                await ref
                                    .read(
                                        transactionTemplatesProvider.notifier)
                                    .updateTemplate(updated);
                              }
                            } else {
                              final template = TransactionTemplate(
                                id: const Uuid().v4(),
                                name: formState.name.trim(),
                                amount: formState.amount,
                                type: formState.type,
                                categoryId: isTransfer
                                    ? null
                                    : formState.categoryId,
                                accountId: formState.accountId,
                                destinationAccountId:
                                    formState.destinationAccountId,
                                assetId: formState.assetId,
                                merchant: formState.merchant,
                                note: formState.note,
                                createdAt: DateTime.now(),
                              );
                              await ref
                                  .read(transactionTemplatesProvider.notifier)
                                  .addTemplate(template);
                            }
                            if (context.mounted) {
                              context.pop();
                              context.showSuccessNotification(
                                isEditing
                                    ? 'Template updated'
                                    : 'Template created',
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

  Future<void> _deleteTemplate(BuildContext context) async {
    final formState = ref.read(transactionTemplateFormProvider);
    if (formState.editingTemplateId == null) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Template',
      message: 'Are you sure you want to delete this template?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted && context.mounted) {
      await ref
          .read(transactionTemplatesProvider.notifier)
          .deleteTemplate(formState.editingTemplateId!);
      if (context.mounted) {
        context.pop();
        context.showSuccessNotification('Template deleted');
      }
    }
  }
}
