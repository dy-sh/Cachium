import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_template.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class TransactionFormState {
  final TransactionType type;
  final double amount;
  final String? categoryId;
  final String? accountId;
  final String? destinationAccountId; // For transfers
  final DateTime date;
  final String? note;
  final String? merchant;
  final String? assetId;
  final String? editingTransactionId;
  // Original values for change tracking (only set when editing)
  final TransactionType? originalType;
  final double? originalAmount;
  final String? originalCategoryId;
  final String? originalAccountId;
  final String? originalDestinationAccountId;
  final String? originalAssetId;
  final DateTime? originalDate;
  final String? originalNote;
  final String? originalMerchant;
  // Settings-driven validation
  final bool allowZeroAmount;

  const TransactionFormState({
    this.type = TransactionType.expense,
    this.amount = 0,
    this.categoryId,
    this.accountId,
    this.destinationAccountId,
    this.assetId,
    required this.date,
    this.note,
    this.merchant,
    this.editingTransactionId,
    this.originalType,
    this.originalAmount,
    this.originalCategoryId,
    this.originalAccountId,
    this.originalDestinationAccountId,
    this.originalAssetId,
    this.originalDate,
    this.originalNote,
    this.originalMerchant,
    this.allowZeroAmount = false,
  });

  bool get isTransfer => type == TransactionType.transfer;

  bool get isValid {
    final amountValid = allowZeroAmount ? amount >= 0 : amount > 0;
    if (isTransfer) {
      return amountValid &&
          accountId != null &&
          destinationAccountId != null &&
          accountId != destinationAccountId;
    }
    return amountValid && categoryId != null && accountId != null;
  }

  bool get isEditing => editingTransactionId != null;

  /// Check if any field has changed from original (for edit mode).
  bool get hasChanges {
    if (!isEditing) return true; // New transaction always "has changes"
    return type != originalType ||
        amount != originalAmount ||
        categoryId != originalCategoryId ||
        accountId != originalAccountId ||
        destinationAccountId != originalDestinationAccountId ||
        assetId != originalAssetId ||
        !_isSameDateTime(date, originalDate) ||
        note != originalNote ||
        merchant != originalMerchant;
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
    String? destinationAccountId,
    bool clearDestinationAccountId = false,
    String? assetId,
    bool clearAssetId = false,
    DateTime? date,
    String? note,
    String? merchant,
    String? editingTransactionId,
    TransactionType? originalType,
    double? originalAmount,
    String? originalCategoryId,
    String? originalAccountId,
    String? originalDestinationAccountId,
    String? originalAssetId,
    DateTime? originalDate,
    String? originalNote,
    String? originalMerchant,
    bool? allowZeroAmount,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      destinationAccountId: clearDestinationAccountId
          ? null
          : (destinationAccountId ?? this.destinationAccountId),
      assetId: clearAssetId ? null : (assetId ?? this.assetId),
      date: date ?? this.date,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      editingTransactionId: editingTransactionId ?? this.editingTransactionId,
      originalType: originalType ?? this.originalType,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCategoryId: originalCategoryId ?? this.originalCategoryId,
      originalAccountId: originalAccountId ?? this.originalAccountId,
      originalDestinationAccountId: originalDestinationAccountId ?? this.originalDestinationAccountId,
      originalAssetId: originalAssetId ?? this.originalAssetId,
      originalDate: originalDate ?? this.originalDate,
      originalNote: originalNote ?? this.originalNote,
      originalMerchant: originalMerchant ?? this.originalMerchant,
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
    // For transfers, category is not required so clear it
    String? categoryId;
    if (type != TransactionType.transfer) {
      final selectLastCategory = ref.read(selectLastCategoryProvider);
      if (selectLastCategory) {
        categoryId = type == TransactionType.income
            ? ref.read(lastUsedIncomeCategoryIdProvider)
            : ref.read(lastUsedExpenseCategoryIdProvider);
      }
    }

    // Also apply last used account if not already set (handles async settings load)
    String? accountId = state.accountId;
    if (accountId == null && !state.isEditing) {
      final selectLastAccount = ref.read(selectLastAccountProvider);
      if (selectLastAccount) {
        accountId = ref.read(lastUsedAccountIdProvider);
      }
    }

    // Clear destination account when switching away from transfer
    final clearDest = type != TransactionType.transfer;

    state = state.copyWith(
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      clearDestinationAccountId: clearDest,
    );
  }

  void setDestinationAccount(String? accountId) {
    state = state.copyWith(
      destinationAccountId: accountId,
      clearDestinationAccountId: accountId == null,
    );
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

  void setMerchant(String? merchant) {
    state = state.copyWith(merchant: merchant);
  }

  void setAsset(String? assetId) {
    state = state.copyWith(assetId: assetId, clearAssetId: assetId == null);
  }

  void clearAsset() {
    state = state.copyWith(clearAssetId: true);
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

  void applyTemplate(TransactionTemplate template) {
    state = state.copyWith(
      type: template.type,
      amount: template.amount ?? state.amount,
      categoryId: template.categoryId,
      accountId: template.accountId,
      destinationAccountId: template.destinationAccountId,
      clearDestinationAccountId: template.destinationAccountId == null,
      assetId: template.assetId,
      clearAssetId: template.assetId == null,
      merchant: template.merchant,
      note: template.note,
    );
  }

  void initForEdit(Transaction transaction) {
    final allowZeroAmount = ref.read(allowZeroAmountProvider);
    state = TransactionFormState(
      type: transaction.type,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      destinationAccountId: transaction.destinationAccountId,
      assetId: transaction.assetId,
      date: transaction.date,
      note: transaction.note,
      merchant: transaction.merchant,
      editingTransactionId: transaction.id,
      // Store original values for change tracking
      originalType: transaction.type,
      originalAmount: transaction.amount,
      originalCategoryId: transaction.categoryId,
      originalAccountId: transaction.accountId,
      originalDestinationAccountId: transaction.destinationAccountId,
      originalAssetId: transaction.assetId,
      originalDate: transaction.date,
      originalNote: transaction.note,
      originalMerchant: transaction.merchant,
      allowZeroAmount: allowZeroAmount,
    );
  }
}

final transactionFormProvider =
    AutoDisposeNotifierProvider<TransactionFormNotifier, TransactionFormState>(() {
  return TransactionFormNotifier();
});
