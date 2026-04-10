import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/attachment_file_service.dart';
import '../../../attachments/data/models/attachment.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_template.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'transaction_form_auto_suggestion.dart';
import 'transaction_form_change_detector.dart';
import 'transaction_form_currency_handler.dart';
import 'transaction_form_validator.dart';
import 'transactions_provider.dart';

export 'transaction_form_change_detector.dart';
export 'transaction_form_validator.dart';

/// Result of a save operation.
class SaveResult {
  final bool success;
  final String message;
  final bool isEdit;

  const SaveResult({required this.success, required this.message, this.isEdit = false});
}

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
  final bool isAcquisitionCost;
  final List<String> tagIds;
  final List<XFile> pendingAttachments;
  final String? editingTransactionId;
  // Original transaction for change tracking (only set when editing)
  final Transaction? originalTransaction;
  // Original tag IDs for change tracking (only set when editing)
  final List<String> originalTagIds;
  // Settings-driven validation
  final bool allowZeroAmount;
  // Auto-categorization tracking
  final bool categoryAutoSelected;
  // Auto-asset-suggestion tracking
  final bool assetAutoSelected;
  // Validation UI state
  final bool showValidationErrors;
  // Save in progress
  final bool isSaving;

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
    this.isAcquisitionCost = false,
    this.tagIds = const [],
    this.pendingAttachments = const [],
    required this.date,
    this.note,
    this.merchant,
    this.editingTransactionId,
    this.originalTransaction,
    this.originalTagIds = const [],
    this.allowZeroAmount = false,
    this.categoryAutoSelected = false,
    this.assetAutoSelected = false,
    this.showValidationErrors = false,
    this.isSaving = false,
  });

  bool get isTransfer => type == TransactionType.transfer;

  bool get isEditing => editingTransactionId != null;

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
    bool? isAcquisitionCost,
    List<String>? tagIds,
    List<XFile>? pendingAttachments,
    DateTime? date,
    String? note,
    bool clearNote = false,
    String? merchant,
    bool clearMerchant = false,
    String? editingTransactionId,
    Transaction? originalTransaction,
    List<String>? originalTagIds,
    bool? allowZeroAmount,
    bool? categoryAutoSelected,
    bool? assetAutoSelected,
    bool? showValidationErrors,
    bool? isSaving,
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
      isAcquisitionCost: isAcquisitionCost ?? this.isAcquisitionCost,
      tagIds: tagIds ?? this.tagIds,
      pendingAttachments: pendingAttachments ?? this.pendingAttachments,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      merchant: clearMerchant ? null : (merchant ?? this.merchant),
      editingTransactionId: editingTransactionId ?? this.editingTransactionId,
      originalTransaction: originalTransaction ?? this.originalTransaction,
      originalTagIds: originalTagIds ?? this.originalTagIds,
      allowZeroAmount: allowZeroAmount ?? this.allowZeroAmount,
      categoryAutoSelected: categoryAutoSelected ?? this.categoryAutoSelected,
      assetAutoSelected: assetAutoSelected ?? this.assetAutoSelected,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Whether a transfer is cross-currency (source and destination have different currencies).
/// Requires account providers to resolve currencies.
final isCrossCurrencyTransferProvider = Provider.autoDispose<bool>((ref) {
  final form = ref.watch(transactionFormProvider);
  if (!form.isTransfer || form.accountId == null || form.destinationAccountId == null) {
    return false;
  }
  final src = ref.watch(accountByIdProvider(form.accountId!));
  final dst = ref.watch(accountByIdProvider(form.destinationAccountId!));
  if (src == null || dst == null) return false;
  return src.currencyCode != dst.currencyCode;
});

class TransactionFormNotifier extends AutoDisposeNotifier<TransactionFormState>
    with TransactionAutoSuggestion, TransactionCurrencyHandler {
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
      clearDestinationAmount: clearDest,
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
    recalculateDestinationAmount();
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
    recalculateDestinationAmount();
  }

  void setCategory(String categoryId) {
    state = state.copyWith(categoryId: categoryId, categoryAutoSelected: false);
    autoSuggestAsset();
  }

  void setAccount(String accountId) {
    refreshExchangeRateForAccount(accountId);
    recalculateDestinationAmount();
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setNote(String? note) {
    state = state.copyWith(note: note);
  }

  void setMerchant(String? merchant) {
    state = state.copyWith(merchant: merchant);

    if (!state.isEditing) {
      if (merchant != null && merchant.trim().isNotEmpty) {
        autoCategorizeByMerchant(merchant);
      }

      autoSuggestAsset();
    }
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

  void setTagIds(List<String> tagIds) {
    state = state.copyWith(tagIds: tagIds);
  }

  void setPendingAttachments(List<XFile> files) {
    state = state.copyWith(pendingAttachments: files);
  }

  void setAsset(String? assetId) {
    state = state.copyWith(
      assetId: assetId,
      clearAssetId: assetId == null,
      isAcquisitionCost: assetId == null ? false : state.isAcquisitionCost,
      assetAutoSelected: false,
    );
  }

  void setIsAcquisitionCost(bool value) {
    state = state.copyWith(isAcquisitionCost: value);
  }

  void clearAsset() {
    state = state.copyWith(clearAssetId: true, isAcquisitionCost: false);
  }

  /// Trigger validation errors to be shown.
  /// Returns true if form is valid.
  bool validate() {
    state = state.copyWith(showValidationErrors: true);
    return state.isValid;
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
      clearMerchant: template.merchant == null,
      note: template.note,
      clearNote: template.note == null,
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
      isAcquisitionCost: transaction.isAcquisitionCost,
      date: transaction.date,
      note: transaction.note,
      merchant: transaction.merchant,
      editingTransactionId: transaction.id,
      originalTransaction: transaction,
      allowZeroAmount: allowZeroAmount,
    );

    // Load tag IDs asynchronously
    _loadTagIds(transaction.id);
  }

  Future<void> _loadTagIds(String transactionId) async {
    try {
      final repo = ref.read(tagRepositoryProvider);
      final tagIds = await repo.getTagIdsForTransaction(transactionId);
      state = state.copyWith(tagIds: tagIds, originalTagIds: tagIds);
    } catch (e) {
      const AppLogger('TransactionForm').warning('failed to load tags: $e');
    }
  }

  /// Save the transaction (create or update). Returns a SaveResult.
  Future<SaveResult> save() async {
    if (state.isSaving) {
      return const SaveResult(success: false, message: 'Save already in progress');
    }
    // Validate first
    if (!validate()) {
      return const SaveResult(success: false, message: 'Please fill in all required fields');
    }

    if (!state.hasChanges) {
      return SaveResult(success: false, message: 'No changes to save', isEdit: state.isEditing);
    }

    state = state.copyWith(isSaving: true);
    try {
      return await _performSave();
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<SaveResult> _performSave() async {

    final formState = state;
    final isEditing = formState.isEditing;
    final isTransfer = formState.isTransfer;
    final mainCurrency = ref.read(mainCurrencyCodeProvider);

    // Refresh conversion rate if needed
    if (isEditing) {
      final originalTx = ref.read(
        transactionByIdProvider(formState.editingTransactionId!),
      );
      if (originalTx == null) {
        return const SaveResult(success: false, message: 'Transaction no longer exists');
      }
      final amountChanged = formState.amount != originalTx.amount;
      final currencyChanged = formState.currencyCode != originalTx.currencyCode;
      final accountChanged = formState.accountId != originalTx.accountId;
      if ((amountChanged || currencyChanged || accountChanged) &&
          formState.currencyCode != mainCurrency) {
        final latestRate = ref.read(exchangeRateProvider((from: formState.currencyCode, to: mainCurrency)));
        if (latestRate != 1.0) {
          setConversionRate(latestRate);
        }
      }
    } else {
      // New transaction: always refresh if foreign currency
      if (formState.currencyCode != mainCurrency) {
        final latestRate = ref.read(exchangeRateProvider((from: formState.currencyCode, to: mainCurrency)));
        if (latestRate != 1.0) {
          setConversionRate(latestRate);
        }
      }
    }
    final savedFormState = state;

    // Validate conversion rate
    if (savedFormState.conversionRate <= 0 || !savedFormState.conversionRate.isFinite) {
      return const SaveResult(success: false, message: 'Invalid conversion rate');
    }

    // Validate account still exists
    final account = ref.read(accountByIdProvider(savedFormState.accountId!));
    if (account == null) {
      return const SaveResult(success: false, message: 'Selected account no longer exists');
    }

    // Validate category still exists (not for transfers)
    if (!isTransfer && savedFormState.categoryId != null) {
      final category = ref.read(categoryByIdProvider(savedFormState.categoryId!));
      if (category == null) {
        return const SaveResult(success: false, message: 'Selected category no longer exists');
      }
    }

    // Block cross-currency transfers without destinationAmount
    if (isTransfer && savedFormState.destinationAccountId != null) {
      final srcAcct = ref.read(accountByIdProvider(savedFormState.accountId!));
      final dstAcct = ref.read(accountByIdProvider(savedFormState.destinationAccountId!));
      if (dstAcct == null) {
        return const SaveResult(success: false, message: 'Destination account no longer exists');
      }
      if (srcAcct != null &&
          srcAcct.currencyCode != dstAcct.currencyCode) {
        if (savedFormState.destinationAmount == null) {
          return const SaveResult(
            success: false,
            message: 'Destination amount is required for cross-currency transfers',
          );
        }
        if (savedFormState.destinationAmount! <= 0) {
          return const SaveResult(
            success: false,
            message: 'Destination amount must be greater than zero',
          );
        }
      }
    }

    // Clear orphaned asset reference silently (asset is optional)
    if (savedFormState.assetId != null) {
      final asset = ref.read(assetByIdProvider(savedFormState.assetId!));
      if (asset == null) {
        clearAsset();
      }
    }

    // Compute main currency snapshot — preserve historical values
    // when only non-currency fields changed during edit
    final bool currencyFieldsChanged = !isEditing || savedFormState.hasCurrencyFieldChanges;

    final mainCurrencyAmount = currencyFieldsChanged
        ? ((savedFormState.currencyCode == mainCurrency)
            ? savedFormState.amount
            : roundCurrency(savedFormState.amount * savedFormState.conversionRate))
        : (savedFormState.originalTransaction?.mainCurrencyAmount ??
            (savedFormState.currencyCode == mainCurrency
                ? savedFormState.amount
                : roundCurrency(savedFormState.amount * savedFormState.conversionRate)));

    final effectiveMainCurrencyCode = currencyFieldsChanged
        ? mainCurrency
        : (savedFormState.originalTransaction?.mainCurrencyCode ?? mainCurrency);

    try {
      if (isEditing) {
        // Update existing transaction
        final originalTransaction = ref.read(
          transactionByIdProvider(savedFormState.editingTransactionId!),
        );
        if (originalTransaction == null) {
          return const SaveResult(success: false, message: 'Transaction no longer exists');
        }
        final updatedTransaction = originalTransaction.copyWith(
          amount: savedFormState.amount,
          type: savedFormState.type,
          categoryId: isTransfer ? '' : savedFormState.categoryId,
          accountId: savedFormState.accountId,
          destinationAccountId: savedFormState.destinationAccountId,
          clearDestinationAccountId: !isTransfer,
          destinationAmount: savedFormState.destinationAmount,
          clearDestinationAmount: !isTransfer || savedFormState.destinationAmount == null,
          assetId: savedFormState.assetId,
          clearAssetId: savedFormState.assetId == null,
          isAcquisitionCost: savedFormState.isAcquisitionCost,
          currencyCode: savedFormState.currencyCode,
          conversionRate: savedFormState.conversionRate,
          mainCurrencyCode: effectiveMainCurrencyCode,
          mainCurrencyAmount: mainCurrencyAmount,
          date: savedFormState.date,
          note: savedFormState.note,
          clearNote: savedFormState.note == null || savedFormState.note!.isEmpty,
          merchant: savedFormState.merchant,
          clearMerchant: savedFormState.merchant == null || savedFormState.merchant!.isEmpty,
        );
        await ref.read(transactionsProvider.notifier)
            .updateTransaction(updatedTransaction);
      } else {
        // Add new transaction
        await ref.read(transactionsProvider.notifier).addTransaction(
              amount: savedFormState.amount,
              type: savedFormState.type,
              categoryId: isTransfer ? '' : savedFormState.categoryId!,
              accountId: savedFormState.accountId!,
              destinationAccountId: savedFormState.destinationAccountId,
              assetId: savedFormState.assetId,
              isAcquisitionCost: savedFormState.isAcquisitionCost,
              currencyCode: savedFormState.currencyCode,
              conversionRate: savedFormState.conversionRate,
              destinationAmount: savedFormState.destinationAmount,
              mainCurrencyCode: effectiveMainCurrencyCode,
              mainCurrencyAmount: mainCurrencyAmount,
              date: savedFormState.date,
              note: savedFormState.note,
              merchant: savedFormState.merchant,
            );
      }

      // Determine saved transaction ID
      final savedTxId = isEditing
          ? savedFormState.editingTransactionId!
          : ref.read(transactionsProvider).valueOrNull?.first.id;

      // Save tag associations
      if (savedTxId != null &&
          (savedFormState.tagIds.isNotEmpty || savedFormState.originalTagIds.isNotEmpty)) {
        final tagRepo = ref.read(tagRepositoryProvider);
        await tagRepo.setTagsForTransaction(savedTxId, savedFormState.tagIds);
      }

      // Process pending attachments
      if (savedTxId != null && savedFormState.pendingAttachments.isNotEmpty) {
        final attachRepo = ref.read(attachmentRepositoryProvider);
        final fileService = AttachmentFileService();
        const uuid = Uuid();

        for (final xfile in savedFormState.pendingAttachments) {
          final result = await fileService.saveImage(File(xfile.path));
          final attachment = Attachment(
            id: uuid.v4(),
            transactionId: savedTxId,
            fileName: xfile.name,
            mimeType: xfile.mimeType ?? 'image/jpeg',
            fileSize: result.fileSize,
            filePath: result.filePath,
            thumbnailPath: result.thumbnailPath,
            createdAt: DateTime.now(),
          );
          await attachRepo.createAttachment(attachment);
        }
      }

      // Save last used account and category after successful save
      await ref.read(settingsProvider.notifier).setLastUsedAccountId(savedFormState.accountId);
      if (!isTransfer) {
        await ref.read(settingsProvider.notifier).setLastUsedCategoryId(
          savedFormState.type,
          savedFormState.categoryId,
        );
      }

      return SaveResult(
        success: true,
        message: isEditing ? 'Transaction updated' : 'Transaction saved',
        isEdit: isEditing,
      );
    } catch (e) {
      return SaveResult(
        success: false,
        message: isEditing
            ? 'Failed to update transaction: ${e.toString()}'
            : 'Failed to save transaction: ${e.toString()}',
      );
    }
  }
}

final transactionFormProvider =
    AutoDisposeNotifierProvider<TransactionFormNotifier, TransactionFormState>(() {
  return TransactionFormNotifier();
});
