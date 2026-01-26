import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/models/account.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

/// Notifier for managing account state.
///
/// Error Handling:
/// - build() lets exceptions propagate to set AsyncValue.error()
/// - Mutation methods catch exceptions and set state to AsyncValue.error()
/// - RepositoryException provides detailed error context
class AccountsNotifier extends AsyncNotifier<List<Account>> {
  final _uuid = const Uuid();

  @override
  Future<List<Account>> build() async {
    final repo = ref.watch(accountRepositoryProvider);
    return repo.getAllAccounts();
  }

  /// Add a new account.
  ///
  /// Returns the new account's ID.
  /// Throws [RepositoryException] on failure, which is caught and
  /// converted to AsyncValue.error().
  Future<String> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    Color? customColor,
  }) async {
    final previousState = state;

    try {
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

      // Optimistically update local state
      state = state.whenData((accounts) => [account, ...accounts]);

      // Save to encrypted database
      await repo.createAccount(account);

      return account.id;
    } catch (e, st) {
      // Revert to previous state on error
      state = previousState;
      // Re-throw for caller to handle (e.g., show error UI)
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.create(entityType: 'Account', cause: e),
        st,
      );
    }
  }

  /// Update an existing account.
  ///
  /// Throws [RepositoryException] on failure.
  Future<void> updateAccount(Account account) async {
    final previousState = state;

    try {
      final repo = ref.read(accountRepositoryProvider);

      // Optimistically update local state
      state = state.whenData(
        (accounts) =>
            accounts.map((a) => a.id == account.id ? account : a).toList(),
      );

      // Update in encrypted database
      await repo.updateAccount(account);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Account', entityId: account.id, cause: e),
        st,
      );
    }
  }

  /// Delete an account.
  ///
  /// Throws [RepositoryException] on failure.
  Future<void> deleteAccount(String id) async {
    final previousState = state;

    try {
      final repo = ref.read(accountRepositoryProvider);

      // Optimistically update local state
      state = state.whenData(
        (accounts) => accounts.where((a) => a.id != id).toList(),
      );

      // Soft delete in database
      await repo.deleteAccount(id);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'Account', entityId: id, cause: e),
        st,
      );
    }
  }

  /// Delete account along with all its transactions (in a single transaction)
  ///
  /// Throws [RepositoryException] on failure.
  Future<void> deleteAccountWithTransactions(String accountId) async {
    final previousState = state;

    try {
      final db = ref.read(databaseProvider);
      final accountRepo = ref.read(accountRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);

      // Get transactions for this account
      final allTransactions = await transactionRepo.getAllTransactions();
      final accountTransactions =
          allTransactions.where((t) => t.accountId == accountId).toList();

      // Optimistically update local state
      state = state.whenData(
        (accounts) => accounts.where((a) => a.id != accountId).toList(),
      );

      // Wrap in transaction to prevent locking
      await db.transaction(() async {
        // Delete all transactions for this account
        for (final tx in accountTransactions) {
          await transactionRepo.deleteTransaction(tx.id);
        }
        // Delete the account
        await accountRepo.deleteAccount(accountId);
      });
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'Account', entityId: accountId, cause: e),
        st,
      );
    }
  }

  /// Move all transactions to another account then delete the source account
  ///
  /// Throws [RepositoryException] on failure.
  Future<void> deleteAccountMovingTransactions(
    String sourceAccountId,
    String targetAccountId,
  ) async {
    final previousState = state;

    try {
      final db = ref.read(databaseProvider);
      final accountRepo = ref.read(accountRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);

      // Get current state
      final accounts = state.valueOrNull;
      if (accounts == null) return;

      final targetAccount =
          accounts.firstWhere((a) => a.id == targetAccountId);

      // Get transactions for the source account
      final allTransactions = await transactionRepo.getAllTransactions();
      final transactionsToMove =
          allTransactions.where((t) => t.accountId == sourceAccountId).toList();

      // Calculate balance effect
      double totalEffect = 0;
      for (final tx in transactionsToMove) {
        totalEffect += tx.type.name == 'income' ? tx.amount : -tx.amount;
      }

      // Optimistically update local state
      state = state.whenData((accts) {
        return accts
            .where((a) => a.id != sourceAccountId)
            .map((a) => a.id == targetAccountId
                ? a.copyWith(balance: a.balance + totalEffect)
                : a)
            .toList();
      });

      // Wrap in transaction to prevent locking
      await db.transaction(() async {
        // Update all transactions to point to target account
        for (final tx in transactionsToMove) {
          final updatedTx = tx.copyWith(accountId: targetAccountId);
          await transactionRepo.updateTransaction(updatedTx);
        }

        // Update target account balance
        final updatedTarget =
            targetAccount.copyWith(balance: targetAccount.balance + totalEffect);
        await accountRepo.updateAccount(updatedTarget);

        // Delete the source account
        await accountRepo.deleteAccount(sourceAccountId);
      });
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'Account', entityId: sourceAccountId, cause: e),
        st,
      );
    }
  }

  /// Update an account's balance by a delta amount.
  ///
  /// Throws [RepositoryException] on failure.
  Future<void> updateBalance(String accountId, double amount) async {
    final previousState = state;

    try {
      final currentState = state.valueOrNull;
      if (currentState == null) return;

      final accountIndex =
          currentState.indexWhere((a) => a.id == accountId);
      if (accountIndex == -1) return;

      final account = currentState[accountIndex];
      final updatedAccount =
          account.copyWith(balance: account.balance + amount);

      // Optimistically update local state
      state = state.whenData(
        (accounts) =>
            accounts.map((a) => a.id == accountId ? updatedAccount : a).toList(),
      );

      // Update in database
      final repo = ref.read(accountRepositoryProvider);
      await repo.updateAccount(updatedAccount);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Account', entityId: accountId, cause: e),
        st,
      );
    }
  }

  /// Refresh accounts from database
  ///
  /// Sets state to AsyncValue.error() on failure.
  Future<void> refresh() async {
    try {
      final repo = ref.read(accountRepositoryProvider);
      state = AsyncData(await repo.getAllAccounts());
    } catch (e, st) {
      state = AsyncError(
        e is AppException ? e : RepositoryException.fetch(entityType: 'Account', cause: e),
        st,
      );
    }
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

final accountsByTypeProvider =
    Provider<Map<AccountType, List<Account>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final accounts = accountsAsync.valueOrEmpty;
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

/// Returns account IDs sorted by most recent transaction usage.
/// Accounts without transactions appear last, sorted by creation date.
final recentlyUsedAccountIdsProvider = Provider<List<String>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  final accounts = ref.watch(accountsProvider).valueOrNull;
  if (accounts == null || accounts.isEmpty) return [];

  // Get most recent transaction date per account
  final Map<String, DateTime> lastUsedMap = {};
  if (transactions != null) {
    for (final tx in transactions) {
      final current = lastUsedMap[tx.accountId];
      if (current == null || tx.createdAt.isAfter(current)) {
        lastUsedMap[tx.accountId] = tx.createdAt;
      }
    }
  }

  // Sort accounts: recently used first, then by account creation date
  final sortedAccounts = List<Account>.from(accounts);
  sortedAccounts.sort((a, b) {
    final aLastUsed = lastUsedMap[a.id];
    final bLastUsed = lastUsedMap[b.id];

    // Both have transactions - sort by last used
    if (aLastUsed != null && bLastUsed != null) {
      return bLastUsed.compareTo(aLastUsed);
    }
    // Only a has transactions
    if (aLastUsed != null) return -1;
    // Only b has transactions
    if (bLastUsed != null) return 1;
    // Neither has transactions - sort by creation date (newest first)
    return b.createdAt.compareTo(a.createdAt);
  });

  return sortedAccounts.map((a) => a.id).toList();
});

/// Checks if an account name already exists (case-insensitive).
/// Returns true if duplicate exists, excluding the account with excludeId.
final accountNameExistsProvider = Provider.family<bool, ({String name, String? excludeId})>((ref, params) {
  final accountsAsync = ref.watch(accountsProvider);
  final accounts = accountsAsync.valueOrEmpty;
  final nameLower = params.name.trim().toLowerCase();
  return accounts.any((a) =>
    a.name.toLowerCase() == nameLower && a.id != params.excludeId
  );
});
