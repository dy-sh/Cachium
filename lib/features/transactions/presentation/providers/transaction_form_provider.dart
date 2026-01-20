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

  const TransactionFormState({
    this.type = TransactionType.expense,
    this.amount = 0,
    this.categoryId,
    this.accountId,
    required this.date,
    this.note,
    this.editingTransactionId,
  });

  bool get isValid =>
      amount > 0 && categoryId != null && accountId != null;

  bool get isEditing => editingTransactionId != null;

  TransactionFormState copyWith({
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? note,
    String? editingTransactionId,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      note: note ?? this.note,
      editingTransactionId: editingTransactionId ?? this.editingTransactionId,
    );
  }
}

class TransactionFormNotifier extends AutoDisposeNotifier<TransactionFormState> {
  @override
  TransactionFormState build() {
    final lastUsedAccountId = ref.read(lastUsedAccountIdProvider);
    return TransactionFormState(
      date: DateTime.now(),
      accountId: lastUsedAccountId,
    );
  }

  void setType(TransactionType type) {
    // Reset category when type changes since categories are type-specific
    state = state.copyWith(type: type, categoryId: null);
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
    final lastUsedAccountId = ref.read(lastUsedAccountIdProvider);
    state = TransactionFormState(
      date: DateTime.now(),
      accountId: lastUsedAccountId,
    );
  }

  void initForEdit(Transaction transaction) {
    state = TransactionFormState(
      type: transaction.type,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      date: transaction.date,
      note: transaction.note,
      editingTransactionId: transaction.id,
    );
  }
}

final transactionFormProvider =
    AutoDisposeNotifierProvider<TransactionFormNotifier, TransactionFormState>(() {
  return TransactionFormNotifier();
});
