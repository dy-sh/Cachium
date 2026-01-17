import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/demo/demo_data.dart';
import '../../data/models/account.dart';

class AccountsNotifier extends Notifier<List<Account>> {
  final _uuid = const Uuid();

  @override
  List<Account> build() {
    return List.from(DemoData.accounts);
  }

  void addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) {
    final account = Account(
      id: _uuid.v4(),
      name: name,
      type: type,
      balance: initialBalance,
      createdAt: DateTime.now(),
    );
    state = [...state, account];
  }

  void updateAccount(Account account) {
    state = state.map((a) => a.id == account.id ? account : a).toList();
  }

  void deleteAccount(String id) {
    state = state.where((a) => a.id != id).toList();
  }

  void updateBalance(String accountId, double amount) {
    state = state.map((a) {
      if (a.id == accountId) {
        return a.copyWith(balance: a.balance + amount);
      }
      return a;
    }).toList();
  }

  Account? getById(String id) {
    try {
      return state.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

final accountsProvider = NotifierProvider<AccountsNotifier, List<Account>>(() {
  return AccountsNotifier();
});

final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountsProvider);
  return accounts.fold(0.0, (sum, account) => sum + account.balance);
});

final accountsByTypeProvider = Provider<Map<AccountType, List<Account>>>((ref) {
  final accounts = ref.watch(accountsProvider);
  final Map<AccountType, List<Account>> grouped = {};

  for (final account in accounts) {
    grouped.putIfAbsent(account.type, () => []).add(account);
  }

  return grouped;
});

final accountByIdProvider = Provider.family<Account?, String>((ref, id) {
  final accounts = ref.watch(accountsProvider);
  try {
    return accounts.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});
