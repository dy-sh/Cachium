import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_template.dart';

class TransactionTemplateFormState {
  final String? editingTemplateId;
  final String name;
  final TransactionType type;
  final double? amount;
  final String? categoryId;
  final String? accountId;
  final String? destinationAccountId;
  final String? assetId;
  final String? merchant;
  final String? note;
  // Original values for change tracking
  final String? originalName;
  final TransactionType? originalType;
  final double? originalAmount;
  final String? originalCategoryId;
  final String? originalAccountId;
  final String? originalDestinationAccountId;
  final String? originalAssetId;
  final String? originalMerchant;
  final String? originalNote;

  const TransactionTemplateFormState({
    this.editingTemplateId,
    this.name = '',
    this.type = TransactionType.expense,
    this.amount,
    this.categoryId,
    this.accountId,
    this.destinationAccountId,
    this.assetId,
    this.merchant,
    this.note,
    this.originalName,
    this.originalType,
    this.originalAmount,
    this.originalCategoryId,
    this.originalAccountId,
    this.originalDestinationAccountId,
    this.originalAssetId,
    this.originalMerchant,
    this.originalNote,
  });

  bool get isEditing => editingTemplateId != null;
  bool get isTransfer => type == TransactionType.transfer;

  bool get isValid => name.trim().isNotEmpty;

  bool get hasChanges {
    if (!isEditing) return true;
    return name != originalName ||
        type != originalType ||
        amount != originalAmount ||
        categoryId != originalCategoryId ||
        accountId != originalAccountId ||
        destinationAccountId != originalDestinationAccountId ||
        assetId != originalAssetId ||
        merchant != originalMerchant ||
        note != originalNote;
  }

  bool get canSave => isValid && hasChanges;

  TransactionTemplateFormState copyWith({
    String? editingTemplateId,
    String? name,
    TransactionType? type,
    double? amount,
    bool clearAmount = false,
    String? categoryId,
    bool clearCategoryId = false,
    String? accountId,
    bool clearAccountId = false,
    String? destinationAccountId,
    bool clearDestinationAccountId = false,
    String? assetId,
    bool clearAssetId = false,
    String? merchant,
    bool clearMerchant = false,
    String? note,
    bool clearNote = false,
    String? originalName,
    TransactionType? originalType,
    double? originalAmount,
    bool clearOriginalAmount = false,
    String? originalCategoryId,
    String? originalAccountId,
    String? originalDestinationAccountId,
    String? originalAssetId,
    String? originalMerchant,
    String? originalNote,
  }) {
    return TransactionTemplateFormState(
      editingTemplateId: editingTemplateId ?? this.editingTemplateId,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: clearAmount ? null : (amount ?? this.amount),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      destinationAccountId: clearDestinationAccountId
          ? null
          : (destinationAccountId ?? this.destinationAccountId),
      assetId: clearAssetId ? null : (assetId ?? this.assetId),
      merchant: clearMerchant ? null : (merchant ?? this.merchant),
      note: clearNote ? null : (note ?? this.note),
      originalName: originalName ?? this.originalName,
      originalType: originalType ?? this.originalType,
      originalAmount: clearOriginalAmount ? null : (originalAmount ?? this.originalAmount),
      originalCategoryId: originalCategoryId ?? this.originalCategoryId,
      originalAccountId: originalAccountId ?? this.originalAccountId,
      originalDestinationAccountId:
          originalDestinationAccountId ?? this.originalDestinationAccountId,
      originalAssetId: originalAssetId ?? this.originalAssetId,
      originalMerchant: originalMerchant ?? this.originalMerchant,
      originalNote: originalNote ?? this.originalNote,
    );
  }
}

class TransactionTemplateFormNotifier
    extends AutoDisposeNotifier<TransactionTemplateFormState> {
  @override
  TransactionTemplateFormState build() {
    return const TransactionTemplateFormState();
  }

  void initForEdit(TransactionTemplate template) {
    state = TransactionTemplateFormState(
      editingTemplateId: template.id,
      name: template.name,
      type: template.type,
      amount: template.amount,
      categoryId: template.categoryId,
      accountId: template.accountId,
      destinationAccountId: template.destinationAccountId,
      assetId: template.assetId,
      merchant: template.merchant,
      note: template.note,
      originalName: template.name,
      originalType: template.type,
      originalAmount: template.amount,
      originalCategoryId: template.categoryId,
      originalAccountId: template.accountId,
      originalDestinationAccountId: template.destinationAccountId,
      originalAssetId: template.assetId,
      originalMerchant: template.merchant,
      originalNote: template.note,
    );
  }

  void setName(String name) => state = state.copyWith(name: name);

  void setType(TransactionType type) {
    final clearDest = type != TransactionType.transfer;
    state = state.copyWith(
      type: type,
      clearCategoryId: true,
      clearDestinationAccountId: clearDest,
    );
  }

  void setAmount(double? amount) {
    if (amount == null || amount == 0) {
      state = state.copyWith(clearAmount: true);
    } else {
      state = state.copyWith(amount: amount);
    }
  }

  void setCategory(String categoryId) =>
      state = state.copyWith(categoryId: categoryId);

  void setAccount(String accountId) =>
      state = state.copyWith(accountId: accountId);

  void setDestinationAccount(String? accountId) {
    state = state.copyWith(
      destinationAccountId: accountId,
      clearDestinationAccountId: accountId == null,
    );
  }

  void setAsset(String? assetId) {
    state = state.copyWith(assetId: assetId, clearAssetId: assetId == null);
  }

  void setMerchant(String? merchant) {
    if (merchant == null || merchant.isEmpty) {
      state = state.copyWith(clearMerchant: true);
    } else {
      state = state.copyWith(merchant: merchant);
    }
  }

  void setNote(String? note) {
    if (note == null || note.isEmpty) {
      state = state.copyWith(clearNote: true);
    } else {
      state = state.copyWith(note: note);
    }
  }
}

final transactionTemplateFormProvider = AutoDisposeNotifierProvider<
    TransactionTemplateFormNotifier, TransactionTemplateFormState>(() {
  return TransactionTemplateFormNotifier();
});
