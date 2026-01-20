import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../data/demo/demo_data.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../data/models/transaction.dart';

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  final _uuid = const Uuid();

  @override
  Future<List<Transaction>> build() async {
    final repo = ref.watch(transactionRepositoryProvider);

    // Check if we have any transactions in the database
    final hasData = await repo.hasTransactions();

    if (!hasData) {
      // Seed demo data on first run
      for (final tx in DemoData.transactions) {
        await repo.createTransaction(tx);
      }
      return List.from(DemoData.transactions);
    }

    // Load existing transactions from database
    return repo.getAllTransactions();
  }

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String accountId,
    required DateTime date,
    String? note,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);

    final transaction = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );

    // Save to encrypted database
    await repo.createTransaction(transaction);

    // Update local state
    state = state.whenData((transactions) => [transaction, ...transactions]);

    // Update account balance
    final balanceChange = type == TransactionType.income ? amount : -amount;
    await ref.read(accountsProvider.notifier).updateBalance(accountId, balanceChange);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final repo = ref.read(transactionRepositoryProvider);

    // Get original transaction to calculate balance difference
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final originalTransaction = currentState.firstWhere((t) => t.id == transaction.id);

    // Calculate balance adjustments
    final sameAccount = originalTransaction.accountId == transaction.accountId;

    if (sameAccount) {
      // Same account: calculate net difference
      // Original effect: income = +amount, expense = -amount
      // New effect: income = +amount, expense = -amount
      // Net change = new effect - original effect
      final originalEffect = originalTransaction.type == TransactionType.income
          ? originalTransaction.amount
          : -originalTransaction.amount;
      final newEffect = transaction.type == TransactionType.income
          ? transaction.amount
          : -transaction.amount;
      final netChange = newEffect - originalEffect;

      if (netChange != 0) {
        await ref.read(accountsProvider.notifier).updateBalance(
              transaction.accountId,
              netChange,
            );
      }
    } else {
      // Different accounts: reverse from original, apply to new
      // First, reverse the original transaction's effect
      final originalBalanceChange = originalTransaction.type == TransactionType.income
          ? -originalTransaction.amount
          : originalTransaction.amount;
      await ref.read(accountsProvider.notifier).updateBalance(
            originalTransaction.accountId,
            originalBalanceChange,
          );

      // Then, apply the new transaction's effect
      final newBalanceChange = transaction.type == TransactionType.income
          ? transaction.amount
          : -transaction.amount;
      await ref.read(accountsProvider.notifier).updateBalance(
            transaction.accountId,
            newBalanceChange,
          );
    }

    // Update in encrypted database
    await repo.updateTransaction(transaction);

    // Update local state
    state = state.whenData(
      (transactions) =>
          transactions.map((t) => t.id == transaction.id ? transaction : t).toList(),
    );
  }

  Future<void> deleteTransaction(String id) async {
    final repo = ref.read(transactionRepositoryProvider);

    // Get transaction before deleting for balance reversal
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final transaction = currentState.firstWhere((t) => t.id == id);

    // Soft delete in database
    await repo.deleteTransaction(id);

    // Update local state
    state = state.whenData(
      (transactions) => transactions.where((t) => t.id != id).toList(),
    );

    // Reverse the balance change
    final balanceChange =
        transaction.type == TransactionType.income ? -transaction.amount : transaction.amount;
    await ref.read(accountsProvider.notifier).updateBalance(
          transaction.accountId,
          balanceChange,
        );
  }

  /// Refresh transactions from database
  Future<void> refresh() async {
    final repo = ref.read(transactionRepositoryProvider);
    state = AsyncData(await repo.getAllTransactions());
  }

  /// Move all transactions from one account to another
  Future<void> moveTransactionsToAccount(String fromAccountId, String toAccountId) async {
    final repo = ref.read(transactionRepositoryProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final transactionsToMove = currentState.where((t) => t.accountId == fromAccountId).toList();

    for (final tx in transactionsToMove) {
      final updatedTx = tx.copyWith(accountId: toAccountId);
      await repo.updateTransaction(updatedTx);
    }

    // Update local state
    state = state.whenData(
      (transactions) => transactions.map((t) {
        if (t.accountId == fromAccountId) {
          return t.copyWith(accountId: toAccountId);
        }
        return t;
      }).toList(),
    );
  }

  /// Delete all transactions for a specific account
  Future<void> deleteTransactionsForAccount(String accountId) async {
    final repo = ref.read(transactionRepositoryProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final transactionsToDelete = currentState.where((t) => t.accountId == accountId).toList();

    for (final tx in transactionsToDelete) {
      await repo.deleteTransaction(tx.id);
    }

    // Update local state
    state = state.whenData(
      (transactions) => transactions.where((t) => t.accountId != accountId).toList(),
    );
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

enum TransactionFilter { all, income, expense }

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  return TransactionFilter.all;
});

final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);

  return transactionsAsync.whenData((transactions) {
    switch (filter) {
      case TransactionFilter.income:
        return transactions.where((t) => t.type == TransactionType.income).toList();
      case TransactionFilter.expense:
        return transactions.where((t) => t.type == TransactionType.expense).toList();
      case TransactionFilter.all:
        return transactions;
    }
  });
});

final groupedTransactionsProvider = Provider<AsyncValue<List<TransactionGroup>>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);

  return filteredAsync.whenData((transactions) {
    // Sort by date descending
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group by date
    final Map<DateTime, List<Transaction>> grouped = {};
    for (final tx in sorted) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    return grouped.entries
        .map((e) => TransactionGroup(date: e.key, transactions: e.value))
        .toList();
  });
});

final recentTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);

  return transactionsAsync.whenData((transactions) {
    // Sort by date descending and take first 5
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return sorted.take(5).toList();
  });
});

final transactionSearchQueryProvider = StateProvider<String>((ref) => '');

final transactionByIdProvider = Provider.family<Transaction?, String>((ref, id) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (transactions == null) return null;
  try {
    return transactions.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});

final transactionsByAccountProvider = Provider.family<List<Transaction>, String>((ref, accountId) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (transactions == null) return [];
  return transactions.where((t) => t.accountId == accountId).toList();
});

final transactionCountByAccountProvider = Provider.family<int, String>((ref, accountId) {
  return ref.watch(transactionsByAccountProvider(accountId)).length;
});

final searchedTransactionsProvider = Provider<AsyncValue<List<TransactionGroup>>>((ref) {
  final groupsAsync = ref.watch(groupedTransactionsProvider);
  final query = ref.watch(transactionSearchQueryProvider).toLowerCase();

  return groupsAsync.whenData((groups) {
    if (query.isEmpty) return groups;

    return groups.map((group) {
      final filteredTxs = group.transactions.where((tx) {
        final note = tx.note?.toLowerCase() ?? '';
        return note.contains(query);
      }).toList();

      return TransactionGroup(date: group.date, transactions: filteredTxs);
    }).where((group) => group.transactions.isNotEmpty).toList();
  });
});
