import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account.dart';

class AccountFormState {
  final AccountType? type;
  final String name;
  final double initialBalance;
  final double transactionDelta; // sum of all transactions for this account
  final String? editingAccountId;
  final int? customColorIndex; // null means use default type color
  final Color? originalCustomColor; // stored color from account being edited

  const AccountFormState({
    this.type,
    this.name = '',
    this.initialBalance = 0,
    this.transactionDelta = 0,
    this.editingAccountId,
    this.customColorIndex,
    this.originalCustomColor,
  });

  // Current balance is computed from initial balance + transactions
  double get currentBalance => initialBalance + transactionDelta;

  bool get isValid => type != null && name.isNotEmpty;

  bool get isEditing => editingAccountId != null;

  bool get hasCustomColor => customColorIndex != null;

  AccountFormState copyWith({
    AccountType? type,
    String? name,
    double? initialBalance,
    double? transactionDelta,
    String? editingAccountId,
    int? customColorIndex,
    bool clearCustomColor = false,
    Color? originalCustomColor,
    bool clearOriginalCustomColor = false,
  }) {
    return AccountFormState(
      type: type ?? this.type,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      transactionDelta: transactionDelta ?? this.transactionDelta,
      editingAccountId: editingAccountId ?? this.editingAccountId,
      customColorIndex: clearCustomColor ? null : (customColorIndex ?? this.customColorIndex),
      originalCustomColor: clearOriginalCustomColor ? null : (originalCustomColor ?? this.originalCustomColor),
    );
  }
}

class AccountFormNotifier extends Notifier<AccountFormState> {
  @override
  AccountFormState build() {
    return const AccountFormState();
  }

  void setType(AccountType type) {
    // Clear custom color when changing type (reset to type's default color)
    state = state.copyWith(type: type, clearCustomColor: true, clearOriginalCustomColor: true);
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setInitialBalance(double balance) {
    state = state.copyWith(initialBalance: balance);
  }

  void reset() {
    state = const AccountFormState();
  }

  void initForEdit(Account account) {
    // Transaction delta = current balance - initial balance
    final transactionDelta = account.balance - account.initialBalance;
    state = AccountFormState(
      type: account.type,
      name: account.name,
      initialBalance: account.initialBalance,
      transactionDelta: transactionDelta,
      editingAccountId: account.id,
      originalCustomColor: account.customColor,
    );
  }

  void setTransactionDelta(double delta) {
    state = state.copyWith(transactionDelta: delta);
  }

  void setCustomColorIndex(int? index) {
    if (index == null) {
      state = state.copyWith(clearCustomColor: true);
    } else {
      state = state.copyWith(customColorIndex: index);
    }
  }
}

final accountFormProvider =
    NotifierProvider<AccountFormNotifier, AccountFormState>(() {
  return AccountFormNotifier();
});
