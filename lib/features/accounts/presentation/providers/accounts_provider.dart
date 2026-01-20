import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../data/demo/demo_data.dart';
import '../../data/models/account.dart';

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  final _uuid = const Uuid();

  @override
  Future<List<Account>> build() async {
    final repo = ref.watch(accountRepositoryProvider);

    // Check if we have any accounts in the database
    final hasData = await repo.hasAccounts();

    if (!hasData) {
      // Seed demo data on first run
      for (final account in DemoData.accounts) {
        await repo.createAccount(account);
      }
      return List.from(DemoData.accounts);
    }

    // Load existing accounts from database
    return repo.getAllAccounts();
  }

  Future<void> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) async {
    final repo = ref.read(accountRepositoryProvider);

    final account = Account(
      id: _uuid.v4(),
      name: name,
      type: type,
      balance: initialBalance,
      initialBalance: initialBalance,
      createdAt: DateTime.now(),
    );

    // Save to encrypted database
    await repo.createAccount(account);

    // Update local state
    state = state.whenData((accounts) => [account, ...accounts]);
  }

  Future<void> updateAccount(Account account) async {
    final repo = ref.read(accountRepositoryProvider);

    // Update in encrypted database
    await repo.updateAccount(account);

    // Update local state
    state = state.whenData(
      (accounts) =>
          accounts.map((a) => a.id == account.id ? account : a).toList(),
    );
  }

  Future<void> deleteAccount(String id) async {
    final repo = ref.read(accountRepositoryProvider);

    // Soft delete in database
    await repo.deleteAccount(id);

    // Update local state
    state = state.whenData(
      (accounts) => accounts.where((a) => a.id != id).toList(),
    );
  }

  Future<void> updateBalance(String accountId, double amount) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final accountIndex = currentState.indexWhere((a) => a.id == accountId);
    if (accountIndex == -1) return;

    final account = currentState[accountIndex];
    final updatedAccount = account.copyWith(balance: account.balance + amount);

    // Update in database
    final repo = ref.read(accountRepositoryProvider);
    await repo.updateAccount(updatedAccount);

    // Update local state
    state = state.whenData(
      (accounts) =>
          accounts.map((a) => a.id == accountId ? updatedAccount : a).toList(),
    );
  }

  /// Refresh accounts from database
  Future<void> refresh() async {
    final repo = ref.read(accountRepositoryProvider);
    state = AsyncData(await repo.getAllAccounts());
  }
}

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<Account>>(() {
  return AccountsNotifier();
});

final totalBalanceProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final accounts = accountsAsync.valueOrNull;
  if (accounts == null) return 0.0;
  return accounts.fold(0.0, (sum, account) => sum + account.balance);
});

final accountsByTypeProvider = Provider<Map<AccountType, List<Account>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final accounts = accountsAsync.valueOrNull ?? [];
  final Map<AccountType, List<Account>> grouped = {};

  for (final account in accounts) {
    grouped.putIfAbsent(account.type, () => []).add(account);
  }

  return grouped;
});

final accountByIdProvider = Provider.family<Account?, String>((ref, id) {
  final accountsAsync = ref.watch(accountsProvider);
  final accounts = accountsAsync.valueOrNull;
  if (accounts == null) return null;
  try {
    return accounts.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});
