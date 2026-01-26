import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class TransactionFormState {
  final TransactionType type;
  final double amount;
  final String? categoryId;
  final String? accountId;
  final DateTime date;
  final String? note;
  final String? editingTransactionId;
  // Original values for change tracking (only set when editing)
  final TransactionType? originalType;
  final double? originalAmount;
  final String? originalCategoryId;
  final String? originalAccountId;
  final DateTime? originalDate;
  final String? originalNote;
  // Settings-driven validation
  final bool allowZeroAmount;

  const TransactionFormState({
    this.type = TransactionType.expense,
    this.amount = 0,
    this.categoryId,
    this.accountId,
    required this.date,
    this.note,
    this.editingTransactionId,
    this.originalType,
    this.originalAmount,
    this.originalCategoryId,
    this.originalAccountId,
    this.originalDate,
    this.originalNote,
    this.allowZeroAmount = false,
  });

  bool get isValid =>
      (allowZeroAmount ? amount >= 0 : amount > 0) && categoryId != null && accountId != null;

  bool get isEditing => editingTransactionId != null;

  /// Check if any field has changed from original (for edit mode).
  bool get hasChanges {
    if (!isEditing) return true; // New transaction always "has changes"
    return type != originalType ||
        amount != originalAmount ||
        categoryId != originalCategoryId ||
        accountId != originalAccountId ||
        !_isSameDateTime(date, originalDate) ||
        note != originalNote;
  }

  /// Compare dates ignoring seconds/milliseconds (only year, month, day, hour, minute).
  bool _isSameDateTime(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  /// Valid and has changes (for Save button).
  bool get canSave => isValid && hasChanges;

  TransactionFormState copyWith({
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? note,
    String? editingTransactionId,
    TransactionType? originalType,
    double? originalAmount,
    String? originalCategoryId,
    String? originalAccountId,
    DateTime? originalDate,
    String? originalNote,
    bool? allowZeroAmount,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      note: note ?? this.note,
      editingTransactionId: editingTransactionId ?? this.editingTransactionId,
      originalType: originalType ?? this.originalType,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCategoryId: originalCategoryId ?? this.originalCategoryId,
      originalAccountId: originalAccountId ?? this.originalAccountId,
      originalDate: originalDate ?? this.originalDate,
      originalNote: originalNote ?? this.originalNote,
      allowZeroAmount: allowZeroAmount ?? this.allowZeroAmount,
    );
  }
}

class TransactionFormNotifier extends AutoDisposeNotifier<TransactionFormState> {
  @override
  TransactionFormState build() {
    final defaultType = ref.read(defaultTransactionTypeProvider);
    final selectLastAccount = ref.read(selectLastAccountProvider);
    final selectLastCategory = ref.read(selectLastCategoryProvider);
    final allowZeroAmount = ref.read(allowZeroAmountProvider);
    final lastUsedAccountId = ref.read(lastUsedAccountIdProvider);
    final lastUsedIncomeCategoryId = ref.read(lastUsedIncomeCategoryIdProvider);
    final lastUsedExpenseCategoryId = ref.read(lastUsedExpenseCategoryIdProvider);

    return TransactionFormState(
      type: defaultType,
      date: DateTime.now(),
      accountId: selectLastAccount ? lastUsedAccountId : null,
      categoryId: selectLastCategory
          ? (defaultType == TransactionType.income
              ? lastUsedIncomeCategoryId
              : lastUsedExpenseCategoryId)
          : null,
      allowZeroAmount: allowZeroAmount,
    );
  }

  void setType(TransactionType type) {
    // Reset category when type changes since categories are type-specific
    // Auto-select last used category for the new type if setting enabled
    final selectLastCategory = ref.read(selectLastCategoryProvider);
    String? categoryId;
    if (selectLastCategory) {
      categoryId = type == TransactionType.income
          ? ref.read(lastUsedIncomeCategoryIdProvider)
          : ref.read(lastUsedExpenseCategoryIdProvider);
    }

    // Also apply last used account if not already set (handles async settings load)
    String? accountId = state.accountId;
    if (accountId == null && !state.isEditing) {
      final selectLastAccount = ref.read(selectLastAccountProvider);
      if (selectLastAccount) {
        accountId = ref.read(lastUsedAccountIdProvider);
      }
    }

    state = state.copyWith(type: type, categoryId: categoryId, accountId: accountId);
  }

  /// Apply last used account if setting is enabled and no account is selected.
  /// Called after form initialization when settings may have loaded.
  void applyLastUsedAccountIfNeeded() {
    if (state.accountId != null) return; // Already has an account
    if (state.isEditing) return; // Don't override in edit mode

    final selectLastAccount = ref.read(selectLastAccountProvider);
    if (!selectLastAccount) return;

    final lastUsedAccountId = ref.read(lastUsedAccountIdProvider);
    if (lastUsedAccountId != null) {
      state = state.copyWith(accountId: lastUsedAccountId);
    }
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setCategory(String categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setAccount(String accountId) {
    state = state.copyWith(accountId: accountId);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setNote(String? note) {
    state = state.copyWith(note: note);
  }

  void reset() {
    final defaultType = ref.read(defaultTransactionTypeProvider);
    final selectLastAccount = ref.read(selectLastAccountProvider);
    final selectLastCategory = ref.read(selectLastCategoryProvider);
    final allowZeroAmount = ref.read(allowZeroAmountProvider);
    final lastUsedAccountId = ref.read(lastUsedAccountIdProvider);
    final lastUsedIncomeCategoryId = ref.read(lastUsedIncomeCategoryIdProvider);
    final lastUsedExpenseCategoryId = ref.read(lastUsedExpenseCategoryIdProvider);

    state = TransactionFormState(
      type: defaultType,
      date: DateTime.now(),
      accountId: selectLastAccount ? lastUsedAccountId : null,
      categoryId: selectLastCategory
          ? (defaultType == TransactionType.income
              ? lastUsedIncomeCategoryId
              : lastUsedExpenseCategoryId)
          : null,
      allowZeroAmount: allowZeroAmount,
    );
  }

  void initForEdit(Transaction transaction) {
    final allowZeroAmount = ref.read(allowZeroAmountProvider);
    state = TransactionFormState(
      type: transaction.type,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      date: transaction.date,
      note: transaction.note,
      editingTransactionId: transaction.id,
      // Store original values for change tracking
      originalType: transaction.type,
      originalAmount: transaction.amount,
      originalCategoryId: transaction.categoryId,
      originalAccountId: transaction.accountId,
      originalDate: transaction.date,
      originalNote: transaction.note,
      allowZeroAmount: allowZeroAmount,
    );
  }
}

final transactionFormProvider =
    AutoDisposeNotifierProvider<TransactionFormNotifier, TransactionFormState>(() {
  return TransactionFormNotifier();
});
