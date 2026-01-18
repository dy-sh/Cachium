import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/buttons/fm_primary_button.dart';
import '../../../../design_system/components/chips/fm_toggle_chip.dart';
import '../../../../design_system/components/inputs/fm_amount_input.dart';
import '../../../../design_system/components/inputs/fm_text_field.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transactions_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(transactionFormProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final accounts = ref.watch(accountsProvider);

    final categories = formState.type == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    final isIncome = formState.type == TransactionType.income;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'New Transaction',
                      style: AppTypography.h3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type toggle
                    Center(
                      child: FMToggleChip(
                        options: const ['Expense', 'Income'],
                        selectedIndex: isIncome ? 1 : 0,
                        colors: const [AppColors.expense, AppColors.income],
                        onChanged: (index) {
                          ref.read(transactionFormProvider.notifier).setType(
                                index == 1 ? TransactionType.income : TransactionType.expense,
                              );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Amount input
                    FMAmountInput(
                      transactionType: formState.type.name,
                      autofocus: true,
                      onChanged: (amount) {
                        ref.read(transactionFormProvider.notifier).setAmount(amount);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Category selection
                    Text('Category', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    _CategorySelector(
                      categories: categories,
                      selectedId: formState.categoryId,
                      onChanged: (id) {
                        ref.read(transactionFormProvider.notifier).setCategory(id);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Account selection
                    Text('Account', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    _AccountSelector(
                      accounts: accounts,
                      selectedId: formState.accountId,
                      onChanged: (id) {
                        ref.read(transactionFormProvider.notifier).setAccount(id);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Date picker
                    _DateSelector(
                      date: formState.date,
                      onChanged: (date) {
                        ref.read(transactionFormProvider.notifier).setDate(date);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Note field
                    FMTextField(
                      label: 'Note (optional)',
                      hint: 'Add a note...',
                      onChanged: (value) {
                        ref.read(transactionFormProvider.notifier).setNote(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // Save button
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: FMPrimaryButton(
                label: 'Save Transaction',
                backgroundColor: AppColors.textPrimary.withOpacity(0.8),
                onPressed: formState.isValid
                    ? () {
                        ref.read(transactionsProvider.notifier).addTransaction(
                              amount: formState.amount,
                              type: formState.type,
                              categoryId: formState.categoryId!,
                              accountId: formState.accountId!,
                              date: formState.date,
                              note: formState.note,
                            );
                        context.pop();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const _CategorySelector({
    required this.categories,
    this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.chipGap),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedId;

          return GestureDetector(
            onTap: () => onChanged(category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color: isSelected ? category.color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected ? category.color : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    category.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? category.color : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const _AccountSelector({
    required this.accounts,
    this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.chipGap),
        itemBuilder: (context, index) {
          final account = accounts[index];
          final isSelected = account.id == selectedId;

          return GestureDetector(
            onTap: () => onChanged(account.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? account.color.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color: isSelected ? account.color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    account.icon,
                    size: 16,
                    color: isSelected ? account.color : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    account.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? account.color : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateSelector({
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.textPrimary,
                      onPrimary: AppColors.background,
                      surface: AppColors.surface,
                      onSurface: AppColors.textPrimary,
                    ),
                    dialogBackgroundColor: AppColors.surface,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  DateFormatter.formatFull(date),
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
