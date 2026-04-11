import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../design_system/design_system.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/recurring_rule.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../assets/presentation/widgets/asset_selector.dart';
import '../../../transactions/presentation/widgets/account_selector.dart';
import '../../../transactions/presentation/widgets/category_selector.dart';
import '../../data/models/bill.dart';
import '../providers/bill_provider.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  final String? billId;

  const BillFormScreen({super.key, this.billId});

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  static const _uuid = Uuid();

  late TextEditingController _nameController;
  late TextEditingController _noteController;

  double _amount = 0;
  String _currencyCode = 'USD';
  String? _categoryId;
  String? _accountId;
  String? _assetId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  bool _reminderEnabled = true;
  int _reminderDaysBefore = 3;

  bool _initialized = false;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  bool get _isEditing => widget.billId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
    _nameController.addListener(_markDirty);
    _noteController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initializeForEdit() {
    if (_initialized || widget.billId == null) return;

    final bills = ref.read(billsProvider).valueOrNull ?? [];
    final bill = bills.where((b) => b.id == widget.billId).firstOrNull;
    if (bill != null) {
      _nameController.text = bill.name;
      _noteController.text = bill.note ?? '';
      _amount = bill.amount;
      _currencyCode = bill.currencyCode;
      _categoryId = bill.categoryId;
      _accountId = bill.accountId;
      _assetId = bill.assetId;
      _dueDate = bill.dueDate;
      _frequency = bill.frequency;
      _reminderEnabled = bill.reminderEnabled;
      _reminderDaysBefore = bill.reminderDaysBefore;
      _initialized = true;
      _hasUnsavedChanges = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeForEdit();
        if (mounted) setState(() {});
      });
    }

    // Initialize currency from settings on first build
    if (!_isEditing && !_initialized) {
      final mainCurrency =
          ref.read(settingsProvider).valueOrNull?.mainCurrencyCode ?? 'USD';
      _currencyCode = mainCurrency;
      _initialized = true;
    }

    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrEmpty;
    final categoriesFoldedCount = ref.watch(categoriesFoldedCountProvider);
    final accountsFoldedCount = ref.watch(accountsFoldedCountProvider);
    final categorySortOption = ref.watch(categorySortOptionProvider);
    final allowSelectParentCategory =
        ref.watch(allowSelectParentCategoryProvider);

    return UnsavedWorkPopScope(
      hasUnsavedWork: _hasUnsavedChanges,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              FormHeader(
                title: _isEditing ? 'Edit Bill' : 'New Bill',
                onClose: () => context.pop(),
                trailing: _isEditing
                    ? GestureDetector(
                        onTap: () => _deleteBill(context),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.15),
                            borderRadius: AppRadius.smAll,
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: AppColors.expense,
                          ),
                        ),
                      )
                    : null,
              ),

              // Scrollable form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Name
                      InputField(
                        label: 'Bill Name',
                        controller: _nameController,
                        hint: 'e.g. Netflix, Rent, Electric...',
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Amount
                      Text('Amount', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AmountInput(
                        initialValue: _amount,
                        transactionType: 'expense',
                        currencyCode: _currencyCode,
                        onChanged: (value) {
                          _amount = value;
                          _markDirty();
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Due Date
                      Text('Due Date', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      _DatePickerTile(
                        date: _dueDate,
                        onChanged: (date) {
                          setState(() => _dueDate = date);
                          _markDirty();
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Frequency
                      Text('Frequency', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: RecurrenceFrequency.values.map((f) {
                          final isSelected = f == _frequency;
                          return SelectionChip(
                            label: f.displayName,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _frequency = f);
                              _markDirty();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Category
                      Text('Category', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      CategorySelector(
                        categories: expenseCategories,
                        selectedId: _categoryId,
                        onChanged: (id) {
                          setState(() => _categoryId = id);
                          _markDirty();
                        },
                        initialVisibleCount: categoriesFoldedCount,
                        sortOption: categorySortOption,
                        allowSelectParentCategory: allowSelectParentCategory,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Account
                      if (accounts.isNotEmpty) ...[
                        Text('Account', style: AppTypography.labelMedium),
                        const SizedBox(height: AppSpacing.sm),
                        AccountSelector(
                          accounts: accounts,
                          selectedId: _accountId,
                          onChanged: (id) {
                            setState(() => _accountId = id);
                            _markDirty();
                          },
                          initialVisibleCount: accountsFoldedCount,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Asset (optional)
                      Builder(builder: (context) {
                        final activeAssets = ref.watch(activeAssetsProvider);
                        if (activeAssets.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Asset (optional)', style: AppTypography.labelMedium),
                            const SizedBox(height: AppSpacing.sm),
                            AssetSelector(
                              assets: activeAssets,
                              selectedId: _assetId,
                              onChanged: (id) {
                                setState(() => _assetId = id);
                                _markDirty();
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        );
                      }),

                      // Reminder toggle
                      Surface(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Reminder',
                                    style: AppTypography.bodyMedium),
                                SizedBox(
                                  height: 24,
                                  width: 44,
                                  child: Switch.adaptive(
                                    value: _reminderEnabled,
                                    onChanged: (value) {
                                      setState(
                                          () => _reminderEnabled = value);
                                      _markDirty();
                                    },
                                    activeTrackColor:
                                        ref.watch(accentColorProvider),
                                  ),
                                ),
                              ],
                            ),
                            if (_reminderEnabled) ...[
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Days before due date',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _ReminderDayButton(
                                        label: '-',
                                        onTap: _reminderDaysBefore > 0
                                            ? () {
                                                setState(() =>
                                                    _reminderDaysBefore--);
                                                _markDirty();
                                              }
                                            : null,
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.md),
                                        child: Text(
                                          '$_reminderDaysBefore',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _ReminderDayButton(
                                        label: '+',
                                        onTap: _reminderDaysBefore < 30
                                            ? () {
                                                setState(() =>
                                                    _reminderDaysBefore++);
                                                _markDirty();
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Note
                      InputField(
                        label: 'Note',
                        controller: _noteController,
                        hint: 'Optional note...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Save button
                      PrimaryButton(
                        label: _isEditing ? 'Save Changes' : 'Add Bill',
                        onPressed: _canSave ? () => _save(context) : null,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _amount > 0 && !_isSaving;

  Future<void> _save(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();

      if (_isEditing) {
        final bills = ref.read(billsProvider).valueOrNull ?? [];
        final existing =
            bills.firstWhere((b) => b.id == widget.billId);
        final updated = existing.copyWith(
          name: _nameController.text.trim(),
          amount: _amount,
          currencyCode: _currencyCode,
          categoryId: _categoryId,
          clearCategoryId: _categoryId == null,
          accountId: _accountId,
          clearAccountId: _accountId == null,
          assetId: _assetId,
          clearAssetId: _assetId == null,
          dueDate: _dueDate,
          frequency: _frequency,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          clearNote: _noteController.text.trim().isEmpty,
          reminderEnabled: _reminderEnabled,
          reminderDaysBefore: _reminderDaysBefore,
        );
        await ref.read(billsProvider.notifier).updateBill(updated);
      } else {
        final bill = Bill(
          id: _uuid.v4(),
          name: _nameController.text.trim(),
          amount: _amount,
          currencyCode: _currencyCode,
          categoryId: _categoryId,
          accountId: _accountId,
          assetId: _assetId,
          dueDate: _dueDate,
          frequency: _frequency,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          reminderEnabled: _reminderEnabled,
          reminderDaysBefore: _reminderDaysBefore,
          createdAt: now,
        );
        await ref.read(billsProvider.notifier).addBill(bill);
      }

      if (context.mounted) {
        context.showSuccessNotification(
          _isEditing ? 'Bill updated' : 'Bill added',
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorNotification(
          e is AppException ? e.userMessage : 'Failed to save bill',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteBill(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete bill?',
      message: 'This bill will be permanently deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(billsProvider.notifier)
            .deleteBill(widget.billId!);
        if (context.mounted) {
          context.showSuccessNotification('Bill deleted');
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          context.showErrorNotification(
            e is AppException ? e.userMessage : 'Failed to delete bill',
          );
        }
      }
    }
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerTile({
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      surface: AppColors.surface,
                      onSurface: AppColors.textPrimary,
                    ),
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
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${date.month}/${date.day}/${date.year}',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderDayButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ReminderDayButton({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.surfaceLight
              : AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: onTap != null
                ? AppColors.textPrimary
                : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
