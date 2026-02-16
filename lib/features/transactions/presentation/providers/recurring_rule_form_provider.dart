import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/models/transaction.dart';

class RecurringRuleFormState {
  final String? editingRuleId;
  final String name;
  final double amount;
  final TransactionType type;
  final String? categoryId;
  final String? accountId;
  final String? destinationAccountId;
  final String? merchant;
  final String? note;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  // Original values for change tracking
  final String? originalName;
  final double? originalAmount;
  final TransactionType? originalType;
  final String? originalCategoryId;
  final String? originalAccountId;
  final String? originalDestinationAccountId;
  final String? originalMerchant;
  final String? originalNote;
  final RecurrenceFrequency? originalFrequency;
  final DateTime? originalStartDate;
  final DateTime? originalEndDate;

  RecurringRuleFormState({
    this.editingRuleId,
    this.name = '',
    this.amount = 0,
    this.type = TransactionType.expense,
    this.categoryId,
    this.accountId,
    this.destinationAccountId,
    this.merchant,
    this.note,
    this.frequency = RecurrenceFrequency.monthly,
    DateTime? startDate,
    this.endDate,
    this.originalName,
    this.originalAmount,
    this.originalType,
    this.originalCategoryId,
    this.originalAccountId,
    this.originalDestinationAccountId,
    this.originalMerchant,
    this.originalNote,
    this.originalFrequency,
    this.originalStartDate,
    this.originalEndDate,
  }) : startDate = startDate ?? DateTime.now();

  bool get isEditing => editingRuleId != null;
  bool get isTransfer => type == TransactionType.transfer;

  bool get isValid {
    if (name.trim().isEmpty) return false;
    if (amount <= 0) return false;
    if (accountId == null) return false;
    if (isTransfer) {
      return destinationAccountId != null && accountId != destinationAccountId;
    }
    return categoryId != null;
  }

  bool get hasChanges {
    if (!isEditing) return true;
    return name != originalName ||
        amount != originalAmount ||
        type != originalType ||
        categoryId != originalCategoryId ||
        accountId != originalAccountId ||
        destinationAccountId != originalDestinationAccountId ||
        merchant != originalMerchant ||
        note != originalNote ||
        frequency != originalFrequency ||
        !_isSameDate(startDate, originalStartDate) ||
        !_isSameDate(endDate, originalEndDate);
  }

  bool _isSameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get canSave => isValid && hasChanges;

  RecurringRuleFormState copyWith({
    String? editingRuleId,
    String? name,
    double? amount,
    TransactionType? type,
    String? categoryId,
    bool clearCategoryId = false,
    String? accountId,
    String? destinationAccountId,
    bool clearDestinationAccountId = false,
    String? merchant,
    bool clearMerchant = false,
    String? note,
    bool clearNote = false,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String? originalName,
    double? originalAmount,
    TransactionType? originalType,
    String? originalCategoryId,
    String? originalAccountId,
    String? originalDestinationAccountId,
    String? originalMerchant,
    String? originalNote,
    RecurrenceFrequency? originalFrequency,
    DateTime? originalStartDate,
    DateTime? originalEndDate,
  }) {
    return RecurringRuleFormState(
      editingRuleId: editingRuleId ?? this.editingRuleId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      accountId: accountId ?? this.accountId,
      destinationAccountId: clearDestinationAccountId
          ? null
          : (destinationAccountId ?? this.destinationAccountId),
      merchant: clearMerchant ? null : (merchant ?? this.merchant),
      note: clearNote ? null : (note ?? this.note),
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      originalName: originalName ?? this.originalName,
      originalAmount: originalAmount ?? this.originalAmount,
      originalType: originalType ?? this.originalType,
      originalCategoryId: originalCategoryId ?? this.originalCategoryId,
      originalAccountId: originalAccountId ?? this.originalAccountId,
      originalDestinationAccountId:
          originalDestinationAccountId ?? this.originalDestinationAccountId,
      originalMerchant: originalMerchant ?? this.originalMerchant,
      originalNote: originalNote ?? this.originalNote,
      originalFrequency: originalFrequency ?? this.originalFrequency,
      originalStartDate: originalStartDate ?? this.originalStartDate,
      originalEndDate: originalEndDate ?? this.originalEndDate,
    );
  }
}

class RecurringRuleFormNotifier
    extends AutoDisposeNotifier<RecurringRuleFormState> {
  @override
  RecurringRuleFormState build() {
    return RecurringRuleFormState();
  }

  void initForEdit(RecurringRule rule) {
    state = RecurringRuleFormState(
      editingRuleId: rule.id,
      name: rule.name,
      amount: rule.amount,
      type: rule.type,
      categoryId: rule.categoryId,
      accountId: rule.accountId,
      destinationAccountId: rule.destinationAccountId,
      merchant: rule.merchant,
      note: rule.note,
      frequency: rule.frequency,
      startDate: rule.startDate,
      endDate: rule.endDate,
      originalName: rule.name,
      originalAmount: rule.amount,
      originalType: rule.type,
      originalCategoryId: rule.categoryId,
      originalAccountId: rule.accountId,
      originalDestinationAccountId: rule.destinationAccountId,
      originalMerchant: rule.merchant,
      originalNote: rule.note,
      originalFrequency: rule.frequency,
      originalStartDate: rule.startDate,
      originalEndDate: rule.endDate,
    );
  }

  void setName(String name) => state = state.copyWith(name: name);
  void setAmount(double amount) => state = state.copyWith(amount: amount);

  void setType(TransactionType type) {
    final clearDest = type != TransactionType.transfer;
    state = state.copyWith(
      type: type,
      clearCategoryId: true,
      clearDestinationAccountId: clearDest,
    );
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

  void setFrequency(RecurrenceFrequency frequency) =>
      state = state.copyWith(frequency: frequency);

  void setStartDate(DateTime date) =>
      state = state.copyWith(startDate: date);

  void setEndDate(DateTime? date) {
    state = state.copyWith(endDate: date, clearEndDate: date == null);
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

final recurringRuleFormProvider = AutoDisposeNotifierProvider<
    RecurringRuleFormNotifier, RecurringRuleFormState>(() {
  return RecurringRuleFormNotifier();
});
