import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/buttons/fm_primary_button.dart';
import '../../../../design_system/components/chips/fm_toggle_chip.dart';
import '../../../../design_system/components/inputs/fm_amount_input.dart';
import '../../../../design_system/components/inputs/fm_date_picker.dart';
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

            // Sticky save button with blur background
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
                    label: 'Save Transaction',
                    backgroundColor: AppColors.accentPrimary,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatefulWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const _CategorySelector({
    required this.categories,
    this.selectedId,
    required this.onChanged,
  });

  @override
  State<_CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<_CategorySelector> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.categories.length > 9;
    final displayCategories = _showAll || !hasMore
        ? widget.categories
        : widget.categories.take(9).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Wrap(
            spacing: AppSpacing.chipGap,
            runSpacing: AppSpacing.chipGap,
            children: displayCategories.map((category) {
              final isSelected = category.id == widget.selectedId;

              return GestureDetector(
                onTap: () {
                  HapticHelper.lightImpact();
                  widget.onChanged(category.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.selectionGlow
                        : AppColors.surface,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: isSelected ? category.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: category.color.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
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
            }).toList(),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll ? 'Show Less' : 'Show All',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountSelector extends StatefulWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const _AccountSelector({
    required this.accounts,
    this.selectedId,
    required this.onChanged,
  });

  @override
  State<_AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<_AccountSelector> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.accounts.length > 6;
    final displayAccounts = _showAll || !hasMore
        ? widget.accounts
        : widget.accounts.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: AppSpacing.chipGap,
              mainAxisSpacing: AppSpacing.chipGap,
            ),
            itemCount: displayAccounts.length,
            itemBuilder: (context, index) {
              final account = displayAccounts[index];
              final isSelected = account.id == widget.selectedId;

              return GestureDetector(
                onTap: () {
                  HapticHelper.lightImpact();
                  widget.onChanged(account.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.selectionGlow
                        : AppColors.surface,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: isSelected ? account.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: account.color.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        account.icon,
                        size: 14,
                        color: isSelected ? account.color : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              account.name,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected ? account.color : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '\$${account.balance.toStringAsFixed(0)}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll ? 'Show Less' : 'Show All',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ],
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isQuickDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);

    return _isSameDay(date, today) ||
        _isSameDay(date, yesterday) ||
        _isSameDay(date, monthStart);
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    HapticHelper.lightImpact();
    final picked = await showFMDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        // Quick date chips
        Wrap(
          spacing: AppSpacing.chipGap,
          runSpacing: AppSpacing.chipGap,
          children: [
            _QuickDateChip(
              label: 'Today',
              isSelected: _isSameDay(date, today),
              onTap: () {
                HapticHelper.lightImpact();
                onChanged(today);
              },
            ),
            _QuickDateChip(
              label: 'Yesterday',
              isSelected: _isSameDay(date, yesterday),
              onTap: () {
                HapticHelper.lightImpact();
                onChanged(yesterday);
              },
            ),
            _QuickDateChip(
              label: 'Start of Month',
              isSelected: _isSameDay(date, monthStart),
              onTap: () {
                HapticHelper.lightImpact();
                onChanged(monthStart);
              },
            ),
            _QuickDateChip(
              label: 'Custom',
              isSelected: !_isQuickDate(date),
              onTap: () => _showCustomDatePicker(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Selected date display (tappable to open date picker)
        GestureDetector(
          onTap: () => _showCustomDatePicker(context),
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
                Expanded(
                  child: Text(
                    DateFormatter.formatFull(date),
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectionGlow : AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPrimary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
