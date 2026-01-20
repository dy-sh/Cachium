import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account.dart';

class AccountFormState {
  final AccountType? type;
  final String name;
  final double initialBalance;
  final String? editingAccountId;

  const AccountFormState({
    this.type,
    this.name = '',
    this.initialBalance = 0,
    this.editingAccountId,
  });

  bool get isValid => type != null && name.isNotEmpty;

  bool get isEditing => editingAccountId != null;

  AccountFormState copyWith({
    AccountType? type,
    String? name,
    double? initialBalance,
    String? editingAccountId,
  }) {
    return AccountFormState(
      type: type ?? this.type,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      editingAccountId: editingAccountId ?? this.editingAccountId,
    );
  }
}

class AccountFormNotifier extends Notifier<AccountFormState> {
  @override
  AccountFormState build() {
    return const AccountFormState();
  }

  void setType(AccountType type) {
    state = state.copyWith(type: type);
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
      initialBalance: account.balance,
      editingAccountId: account.id,
    );
  }
}

final accountFormProvider =
    NotifierProvider<AccountFormNotifier, AccountFormState>(() {
  return AccountFormNotifier();
});
