import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/models/account.dart';

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  final _uuid = const Uuid();

  @override
  Future<List<Account>> build() async {
    final repo = ref.watch(accountRepositoryProvider);
    return repo.getAllAccounts();
  }

  Future<void> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    Color? customColor,
  }) async {
    final repo = ref.read(accountRepositoryProvider);

    final account = Account(
      id: _uuid.v4(),
      name: name,
      type: type,
      balance: initialBalance,
      initialBalance: initialBalance,
      customColor: customColor,
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

  /// Delete account along with all its transactions (in a single transaction)
  Future<void> deleteAccountWithTransactions(String accountId) async {
    final db = ref.read(databaseProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final transactionRepo = ref.read(transactionRepositoryProvider);

    // Get transactions for this account
    final allTransactions = await transactionRepo.getAllTransactions();
    final accountTransactions = allTransactions.where((t) => t.accountId == accountId).toList();

    // Wrap in transaction to prevent locking
    await db.transaction(() async {
      // Delete all transactions for this account
      for (final tx in accountTransactions) {
        await transactionRepo.deleteTransaction(tx.id);
      }
      // Delete the account
      await accountRepo.deleteAccount(accountId);
    });

    // Update local state
    state = state.whenData(
      (accounts) => accounts.where((a) => a.id != accountId).toList(),
    );
  }

  /// Move all transactions to another account then delete the source account (in a single transaction)
  Future<void> deleteAccountMovingTransactions(String sourceAccountId, String targetAccountId) async {
    final db = ref.read(databaseProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final transactionRepo = ref.read(transactionRepositoryProvider);

    // Get current state
    final accounts = state.valueOrNull;
    if (accounts == null) return;

    final targetAccount = accounts.firstWhere((a) => a.id == targetAccountId);

    // Get transactions for the source account
    final allTransactions = await transactionRepo.getAllTransactions();
    final transactionsToMove = allTransactions.where((t) => t.accountId == sourceAccountId).toList();

    // Calculate balance effect
    double totalEffect = 0;
    for (final tx in transactionsToMove) {
      totalEffect += tx.type.name == 'income' ? tx.amount : -tx.amount;
    }

    // Wrap in transaction to prevent locking
    await db.transaction(() async {
      // Update all transactions to point to target account
      for (final tx in transactionsToMove) {
        final updatedTx = tx.copyWith(accountId: targetAccountId);
        await transactionRepo.updateTransaction(updatedTx);
      }

      // Update target account balance
      final updatedTarget = targetAccount.copyWith(balance: targetAccount.balance + totalEffect);
      await accountRepo.updateAccount(updatedTarget);

      // Delete the source account
      await accountRepo.deleteAccount(sourceAccountId);
    });

    // Update local state
    state = state.whenData((accts) {
      return accts
          .where((a) => a.id != sourceAccountId)
          .map((a) => a.id == targetAccountId
              ? a.copyWith(balance: a.balance + totalEffect)
              : a)
          .toList();
    });
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
