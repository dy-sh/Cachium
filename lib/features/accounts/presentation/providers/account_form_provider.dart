import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account.dart';

class AccountFormState {
  final AccountType? type;
  final String name;
  final double initialBalance;
  final double currentBalance;
  final String? editingAccountId;
  final int? customColorIndex; // null means use default type color
  final Color? originalCustomColor; // stored color from account being edited

  const AccountFormState({
    this.type,
    this.name = '',
    this.initialBalance = 0,
    this.currentBalance = 0,
    this.editingAccountId,
    this.customColorIndex,
    this.originalCustomColor,
  });

  bool get isValid => type != null && name.isNotEmpty;

  bool get isEditing => editingAccountId != null;

  bool get hasCustomColor => customColorIndex != null;

  AccountFormState copyWith({
    AccountType? type,
    String? name,
    double? initialBalance,
    double? currentBalance,
    String? editingAccountId,
    int? customColorIndex,
    bool clearCustomColor = false,
    Color? originalCustomColor,
  }) {
    return AccountFormState(
      type: type ?? this.type,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      editingAccountId: editingAccountId ?? this.editingAccountId,
      customColorIndex: clearCustomColor ? null : (customColorIndex ?? this.customColorIndex),
      originalCustomColor: originalCustomColor ?? this.originalCustomColor,
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
    state = state.copyWith(type: type, clearCustomColor: true);
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
    state = AccountFormState(
      type: account.type,
      name: account.name,
      initialBalance: account.initialBalance,
      currentBalance: account.balance,
      editingAccountId: account.id,
      originalCustomColor: account.customColor,
    );
  }

  void setCurrentBalance(double balance) {
    state = state.copyWith(currentBalance: balance);
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
