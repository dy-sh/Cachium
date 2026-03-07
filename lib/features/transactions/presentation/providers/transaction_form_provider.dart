import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_template.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class TransactionFormState {
  final TransactionType type;
  final double amount;
  final String? categoryId;
  final String? accountId;
  final String? destinationAccountId; // For transfers
  final String currencyCode;

  /// Multiplier: `amount * conversionRate ≈ mainCurrencyAmount`.
  final double conversionRate;

  final double? destinationAmount;
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
  final double? originalDestinationAmount;
  final String? originalAssetId;
  final DateTime? originalDate;
  final String? originalNote;
  final String? originalMerchant;
  final String? originalCurrencyCode;
  final double? originalConversionRate;
  // Settings-driven validation
  final bool allowZeroAmount;

  const TransactionFormState({
    this.type = TransactionType.expense,
    this.amount = 0,
    this.categoryId,
    this.accountId,
    this.destinationAccountId,
    this.currencyCode = 'USD',
    this.conversionRate = 1.0,
    this.destinationAmount,
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
    this.originalDestinationAmount,
    this.originalAssetId,
    this.originalDate,
    this.originalNote,
    this.originalMerchant,
    this.originalCurrencyCode,
    this.originalConversionRate,
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
        destinationAmount != originalDestinationAmount ||
        assetId != originalAssetId ||
        !_isSameDateTime(date, originalDate) ||
        note != originalNote ||
        merchant != originalMerchant ||
        currencyCode != originalCurrencyCode ||
        conversionRate != originalConversionRate;
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
    String? currencyCode,
    double? conversionRate,
    double? destinationAmount,
    bool clearDestinationAmount = false,
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
    double? originalDestinationAmount,
    String? originalAssetId,
    DateTime? originalDate,
    String? originalNote,
    String? originalMerchant,
    String? originalCurrencyCode,
    double? originalConversionRate,
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
      currencyCode: currencyCode ?? this.currencyCode,
      conversionRate: conversionRate ?? this.conversionRate,
      destinationAmount: clearDestinationAmount
          ? null
          : (destinationAmount ?? this.destinationAmount),
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
      originalDestinationAmount: originalDestinationAmount ?? this.originalDestinationAmount,
      originalAssetId: originalAssetId ?? this.originalAssetId,
      originalDate: originalDate ?? this.originalDate,
      originalNote: originalNote ?? this.originalNote,
      originalMerchant: originalMerchant ?? this.originalMerchant,
      originalCurrencyCode: originalCurrencyCode ?? this.originalCurrencyCode,
      originalConversionRate: originalConversionRate ?? this.originalConversionRate,
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

    final mainCurrency = ref.read(mainCurrencyCodeProvider);

    return TransactionFormState(
      type: defaultType,
      date: DateTime.now(),
      currencyCode: mainCurrency,
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
    if (accountId == null) {
      state = state.copyWith(
        clearDestinationAccountId: true,
        clearDestinationAmount: true,
      );
      return;
    }

    state = state.copyWith(
      destinationAccountId: accountId,
    );
    _recalculateDestinationAmount();
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
    _recalculateDestinationAmount();
  }

  void setCategory(String categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setAccount(String accountId) {
    // Set currency from account
    final account = ref.read(accountByIdProvider(accountId));
    final currencyCode = account?.currencyCode ?? state.currencyCode;
    final mainCurrency = ref.read(mainCurrencyCodeProvider);

    double conversionRate = 1.0;
    if (currencyCode != mainCurrency) {
      // Auto-refresh rates if stale and this is a foreign-currency account
      final isStale = ref.read(exchangeRatesStaleProvider);
      if (isStale) {
        ref.read(exchangeRatesProvider.notifier).refresh();
      }

      final rate = ref.read(exchangeRateProvider((from: currencyCode, to: mainCurrency)));
      conversionRate = rate;
    }

    state = state.copyWith(
      accountId: accountId,
      currencyCode: currencyCode,
      conversionRate: conversionRate,
    );
    _recalculateDestinationAmount();
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

  void setConversionRate(double rate) {
    state = state.copyWith(conversionRate: rate);
  }

  void setDestinationAmount(double? amount) {
    state = state.copyWith(
      destinationAmount: amount,
      clearDestinationAmount: amount == null,
    );
  }

  void _recalculateDestinationAmount() {
    if (!state.isTransfer || state.accountId == null || state.destinationAccountId == null) {
      return;
    }
    final srcAccount = ref.read(accountByIdProvider(state.accountId!));
    final dstAccount = ref.read(accountByIdProvider(state.destinationAccountId!));
    if (srcAccount == null || dstAccount == null) return;

    if (srcAccount.currencyCode == dstAccount.currencyCode) {
      // Same currency - no destinationAmount needed
      state = state.copyWith(clearDestinationAmount: true);
      return;
    }

    // Cross-currency: calculate using live rates
    if (state.amount > 0) {
      final rate = ref.read(exchangeRateProvider((from: srcAccount.currencyCode, to: dstAccount.currencyCode)));
      final converted = state.amount * rate;
      state = state.copyWith(destinationAmount: roundCurrency(converted));
    }
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
    final mainCurrency = ref.read(mainCurrencyCodeProvider);

    state = TransactionFormState(
      type: defaultType,
      date: DateTime.now(),
      currencyCode: mainCurrency,
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
      currencyCode: transaction.currencyCode,
      conversionRate: transaction.conversionRate,
      destinationAmount: transaction.destinationAmount,
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
      originalDestinationAmount: transaction.destinationAmount,
      originalAssetId: transaction.assetId,
      originalDate: transaction.date,
      originalNote: transaction.note,
      originalMerchant: transaction.merchant,
      originalCurrencyCode: transaction.currencyCode,
      originalConversionRate: transaction.conversionRate,
      allowZeroAmount: allowZeroAmount,
    );
  }
}

final transactionFormProvider =
    AutoDisposeNotifierProvider<TransactionFormNotifier, TransactionFormState>(() {
  return TransactionFormNotifier();
});
