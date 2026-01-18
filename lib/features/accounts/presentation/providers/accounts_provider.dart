import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/crud_notifier.dart';
import '../../../../data/demo/demo_data.dart';
import '../../data/models/account.dart';

class AccountsNotifier extends CrudNotifier<Account> {
  final _uuid = const Uuid();

  @override
  String getId(Account item) => item.id;

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
    add(account);
  }

  void updateAccount(Account account) => update(account);

  void deleteAccount(String id) => delete(id);

  void updateBalance(String accountId, double amount) {
    state = state.map((a) {
      if (a.id == accountId) {
        return a.copyWith(balance: a.balance + amount);
      }
      return a;
    }).toList();
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
