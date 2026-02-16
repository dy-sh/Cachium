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
import '../../../../design_system/components/chips/selection_chip.dart';
import '../../../../design_system/components/chips/toggle_chip.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/inputs/amount_input.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/models/transaction.dart';
import '../providers/recurring_rule_form_provider.dart';
import '../providers/recurring_rules_provider.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_selector.dart';
import '../widgets/date_selector.dart';

class RecurringRuleFormScreen extends ConsumerStatefulWidget {
  final String? ruleId;

  const RecurringRuleFormScreen({super.key, this.ruleId});

  @override
  ConsumerState<RecurringRuleFormScreen> createState() =>
      _RecurringRuleFormScreenState();
}

class _RecurringRuleFormScreenState
    extends ConsumerState<RecurringRuleFormScreen> {
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
    if (_initialized || widget.ruleId == null) return;

    final rules = ref.read(recurringRulesProvider).valueOrNull ?? [];
    final rule = rules.where((r) => r.id == widget.ruleId).firstOrNull;
    if (rule != null) {
      ref.read(recurringRuleFormProvider.notifier).initForEdit(rule);
      _nameController.text = rule.name;
      _noteController.text = rule.note ?? '';
      _merchantController.text = rule.merchant ?? '';
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ruleId != null && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeForEdit();
        if (mounted) setState(() {});
      });
    }

    final formState = ref.watch(recurringRuleFormProvider);
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

    final categories = formState.type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditing ? 'Edit Rule' : 'New Rule',
              onClose: () => context.pop(),
              trailing: isEditing
                  ? GestureDetector(
                      onTap: () => _deleteRule(context),
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
                      key: ValueKey('name_${formState.editingRuleId}'),
                      label: 'Rule Name',
                      hint: 'e.g. Monthly Rent, Salary...',
                      controller: _nameController,
                      autofocus: !isEditing,
                      onChanged: (value) {
                        ref
                            .read(recurringRuleFormProvider.notifier)
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
                              .read(recurringRuleFormProvider.notifier)
                              .setType(type);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    AmountInput(
                      key: ValueKey('amount_${formState.editingRuleId}'),
                      initialValue:
                          formState.amount > 0 ? formState.amount : null,
                      transactionType: formState.type.name,
                      onChanged: (amount) {
                        ref
                            .read(recurringRuleFormProvider.notifier)
                            .setAmount(amount);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text('Frequency', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: RecurrenceFrequency.values.map((freq) {
                        return SelectionChip(
                          label: freq.displayName,
                          icon: freq.icon,
                          isSelected: formState.frequency == freq,
                          onTap: () {
                            ref
                                .read(recurringRuleFormProvider.notifier)
                                .setFrequency(freq);
                          },
                        );
                      }).toList(),
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
                        recentCategoryIds: const [],
                        allowSelectParentCategory: allowSelectParentCategory,
                        onChanged: (id) {
                          ref
                              .read(recurringRuleFormProvider.notifier)
                              .setCategory(id);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    Text(isTransfer ? 'From Account' : 'Account',
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
                            .read(recurringRuleFormProvider.notifier)
                            .setAccount(id);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (isTransfer) ...[
                      Text('To Account', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AccountSelector(
                        accounts: accounts,
                        selectedId: formState.destinationAccountId,
                        recentAccountIds: const [],
                        initialVisibleCount: accountsFoldedCount,
                        excludeAccountId: formState.accountId,
                        onChanged: (id) {
                          ref
                              .read(recurringRuleFormProvider.notifier)
                              .setDestinationAccount(id);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    Text('Start Date', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    DateSelector(
                      date: formState.startDate,
                      onChanged: (date) {
                        ref
                            .read(recurringRuleFormProvider.notifier)
                            .setStartDate(date);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Row(
                      children: [
                        Text('End Date (optional)',
                            style: AppTypography.labelMedium),
                        const Spacer(),
                        if (formState.endDate != null)
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(recurringRuleFormProvider.notifier)
                                  .setEndDate(null);
                            },
                            child: Text(
                              'Clear',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (formState.endDate != null)
                      DateSelector(
                        date: formState.endDate!,
                        onChanged: (date) {
                          ref
                              .read(recurringRuleFormProvider.notifier)
                              .setEndDate(date);
                        },
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(recurringRuleFormProvider.notifier)
                              .setEndDate(DateTime.now()
                                  .add(const Duration(days: 365)));
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.calendarPlus,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Set end date',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxl),

                    InputField(
                      key: ValueKey('merchant_${formState.editingRuleId}'),
                      label: 'Merchant (optional)',
                      hint: 'e.g. Amazon, Starbucks...',
                      controller: _merchantController,
                      onChanged: (value) {
                        ref
                            .read(recurringRuleFormProvider.notifier)
                            .setMerchant(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    InputField(
                      key: ValueKey('note_${formState.editingRuleId}'),
                      label: 'Note (optional)',
                      hint: 'Add a note...',
                      controller: _noteController,
                      onChanged: (value) {
                        ref
                            .read(recurringRuleFormProvider.notifier)
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
                    label: isEditing ? 'Save Changes' : 'Save Rule',
                    onPressed: formState.canSave
                        ? () async {
                            if (isEditing) {
                              final rules = ref
                                      .read(recurringRulesProvider)
                                      .valueOrNull ??
                                  [];
                              final original = rules
                                  .where(
                                      (r) => r.id == formState.editingRuleId)
                                  .firstOrNull;
                              if (original != null) {
                                final updated = original.copyWith(
                                  name: formState.name.trim(),
                                  amount: formState.amount,
                                  type: formState.type,
                                  categoryId: isTransfer
                                      ? original.categoryId
                                      : formState.categoryId!,
                                  accountId: formState.accountId!,
                                  destinationAccountId:
                                      formState.destinationAccountId,
                                  clearDestinationAccountId: !isTransfer,
                                  merchant: formState.merchant,
                                  note: formState.note,
                                  frequency: formState.frequency,
                                  startDate: formState.startDate,
                                  endDate: formState.endDate,
                                  clearEndDate: formState.endDate == null,
                                );
                                await ref
                                    .read(recurringRulesProvider.notifier)
                                    .updateRule(updated);
                              }
                            } else {
                              final rule = RecurringRule(
                                id: const Uuid().v4(),
                                name: formState.name.trim(),
                                amount: formState.amount,
                                type: formState.type,
                                categoryId: isTransfer
                                    ? ''
                                    : formState.categoryId!,
                                accountId: formState.accountId!,
                                destinationAccountId:
                                    formState.destinationAccountId,
                                merchant: formState.merchant,
                                note: formState.note,
                                frequency: formState.frequency,
                                startDate: formState.startDate,
                                endDate: formState.endDate,
                                lastGeneratedDate: formState.startDate
                                    .subtract(const Duration(days: 1)),
                                createdAt: DateTime.now(),
                              );
                              await ref
                                  .read(recurringRulesProvider.notifier)
                                  .addRule(rule);
                            }
                            if (context.mounted) {
                              context.pop();
                              context.showSuccessNotification(
                                isEditing
                                    ? 'Rule updated'
                                    : 'Rule created',
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

  Future<void> _deleteRule(BuildContext context) async {
    final formState = ref.read(recurringRuleFormProvider);
    if (formState.editingRuleId == null) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Rule',
      message:
          'Are you sure you want to delete this rule? This will not affect already generated transactions.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted && context.mounted) {
      await ref
          .read(recurringRulesProvider.notifier)
          .deleteRule(formState.editingRuleId!);
      if (context.mounted) {
        context.pop();
        context.showSuccessNotification('Recurring rule deleted');
      }
    }
  }
}
