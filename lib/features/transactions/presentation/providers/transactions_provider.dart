import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../data/models/transaction.dart';

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  final _uuid = const Uuid();

  @override
  Future<List<Transaction>> build() async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getAllTransactions();
  }

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String accountId,
    String? destinationAccountId,
    required DateTime date,
    String? note,
    String? merchant,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);

    final transaction = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      destinationAccountId: destinationAccountId,
      date: date,
      note: note,
      merchant: merchant,
      createdAt: DateTime.now(),
    );

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Save to encrypted database
      await repo.createTransaction(transaction);

      // Update account balances
      if (type == TransactionType.transfer && destinationAccountId != null) {
        // Transfer: debit source, credit destination
        await ref.read(accountsProvider.notifier).updateBalance(accountId, -amount);
        await ref.read(accountsProvider.notifier).updateBalance(destinationAccountId, amount);
      } else {
        final balanceChange = type == TransactionType.income ? amount : -amount;
        await ref.read(accountsProvider.notifier).updateBalance(accountId, balanceChange);
      }
    });

    // Update local state
    state = state.whenData((transactions) => [transaction, ...transactions]);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);

    // Get original transaction to calculate balance difference
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final originalTransaction = currentState.firstWhere((t) => t.id == transaction.id);

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Reverse original balance effects
      if (originalTransaction.type == TransactionType.transfer) {
        await ref.read(accountsProvider.notifier).updateBalance(
              originalTransaction.accountId, originalTransaction.amount);
        if (originalTransaction.destinationAccountId != null) {
          await ref.read(accountsProvider.notifier).updateBalance(
                originalTransaction.destinationAccountId!, -originalTransaction.amount);
        }
      } else {
        final reverseChange = originalTransaction.type == TransactionType.income
            ? -originalTransaction.amount
            : originalTransaction.amount;
        await ref.read(accountsProvider.notifier).updateBalance(
              originalTransaction.accountId, reverseChange);
      }

      // Apply new balance effects
      if (transaction.type == TransactionType.transfer) {
        await ref.read(accountsProvider.notifier).updateBalance(
              transaction.accountId, -transaction.amount);
        if (transaction.destinationAccountId != null) {
          await ref.read(accountsProvider.notifier).updateBalance(
                transaction.destinationAccountId!, transaction.amount);
        }
      } else {
        final newChange = transaction.type == TransactionType.income
            ? transaction.amount
            : -transaction.amount;
        await ref.read(accountsProvider.notifier).updateBalance(
              transaction.accountId, newChange);
      }

      // Update in encrypted database
      await repo.updateTransaction(transaction);
    });

    // Update local state
    state = state.whenData(
      (transactions) =>
          transactions.map((t) => t.id == transaction.id ? transaction : t).toList(),
    );
  }

  Future<void> deleteTransaction(String id) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);

    // Get transaction before deleting for balance reversal
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final transaction = currentState.firstWhere((t) => t.id == id);

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Soft delete in database
      await repo.deleteTransaction(id);

      // Reverse the balance change
      if (transaction.type == TransactionType.transfer) {
        // Reverse transfer: credit source, debit destination
        await ref.read(accountsProvider.notifier).updateBalance(
              transaction.accountId, transaction.amount);
        if (transaction.destinationAccountId != null) {
          await ref.read(accountsProvider.notifier).updateBalance(
                transaction.destinationAccountId!, -transaction.amount);
        }
      } else {
        final balanceChange =
            transaction.type == TransactionType.income ? -transaction.amount : transaction.amount;
        await ref.read(accountsProvider.notifier).updateBalance(
              transaction.accountId,
              balanceChange,
            );
      }
    });

    // Update local state
    state = state.whenData(
      (transactions) => transactions.where((t) => t.id != id).toList(),
    );

    ref.invalidate(deletedTransactionsProvider);
  }

  /// Restore a previously soft-deleted transaction
  Future<void> restoreTransaction(Transaction transaction) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);

    await db.transaction(() async {
      // Restore in database
      await repo.restoreTransaction(transaction.id);

      // Re-apply the balance change to the account
      if (transaction.type == TransactionType.transfer) {
        await ref.read(accountsProvider.notifier).updateBalance(
              transaction.accountId, -transaction.amount);
        if (transaction.destinationAccountId != null) {
          await ref.read(accountsProvider.notifier).updateBalance(
                transaction.destinationAccountId!, transaction.amount);
        }
      } else {
        final balanceChange =
            transaction.type == TransactionType.income ? transaction.amount : -transaction.amount;
        await ref.read(accountsProvider.notifier).updateBalance(
              transaction.accountId,
              balanceChange,
            );
      }
    });

    // Re-insert into local state (sorted by date descending)
    state = state.whenData((transactions) {
      final updated = [transaction, ...transactions];
      updated.sort((a, b) => b.date.compareTo(a.date));
      return updated;
    });

    ref.invalidate(deletedTransactionsProvider);
  }

  /// Batch delete multiple transactions
  Future<void> deleteTransactions(List<String> ids) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    await db.transaction(() async {
      for (final id in ids) {
        final transaction = currentState.firstWhere((t) => t.id == id);
        await repo.deleteTransaction(id);

        // Reverse the balance change
        if (transaction.type == TransactionType.transfer) {
          await ref.read(accountsProvider.notifier).updateBalance(
                transaction.accountId, transaction.amount);
          if (transaction.destinationAccountId != null) {
            await ref.read(accountsProvider.notifier).updateBalance(
                  transaction.destinationAccountId!, -transaction.amount);
          }
        } else {
          final balanceChange =
              transaction.type == TransactionType.income ? -transaction.amount : transaction.amount;
          await ref.read(accountsProvider.notifier).updateBalance(
                transaction.accountId,
                balanceChange,
              );
        }
      }
    });

    // Update local state
    final idSet = ids.toSet();
    state = state.whenData(
      (transactions) => transactions.where((t) => !idSet.contains(t.id)).toList(),
    );

    ref.invalidate(deletedTransactionsProvider);
  }

  /// Batch restore multiple previously soft-deleted transactions
  Future<void> restoreTransactions(List<Transaction> transactionsToRestore) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);

    await db.transaction(() async {
      for (final transaction in transactionsToRestore) {
        await repo.restoreTransaction(transaction.id);

        // Re-apply the balance change
        if (transaction.type == TransactionType.transfer) {
          await ref.read(accountsProvider.notifier).updateBalance(
                transaction.accountId, -transaction.amount);
          if (transaction.destinationAccountId != null) {
            await ref.read(accountsProvider.notifier).updateBalance(
                  transaction.destinationAccountId!, transaction.amount);
          }
        } else {
          final balanceChange =
              transaction.type == TransactionType.income ? transaction.amount : -transaction.amount;
          await ref.read(accountsProvider.notifier).updateBalance(
                transaction.accountId,
                balanceChange,
              );
        }
      }
    });

    // Re-insert into local state
    state = state.whenData((transactions) {
      final updated = [...transactionsToRestore, ...transactions];
      updated.sort((a, b) => b.date.compareTo(a.date));
      return updated;
    });

    ref.invalidate(deletedTransactionsProvider);
  }

  /// Refresh transactions from database
  Future<void> refresh() async {
    final repo = ref.read(transactionRepositoryProvider);
    state = AsyncData(await repo.getAllTransactions());
  }

  /// Move all transactions from one account to another
  Future<void> moveTransactionsToAccount(String fromAccountId, String toAccountId) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final transactionsToMove = currentState.where((t) => t.accountId == fromAccountId).toList();

    if (transactionsToMove.isEmpty) return;

    // Calculate total balance effect of all transactions
    // Income = +amount, Expense = -amount
    double totalEffect = 0;
    for (final tx in transactionsToMove) {
      if (tx.type == TransactionType.income) {
        totalEffect += tx.amount;
      } else {
        totalEffect -= tx.amount;
      }
    }

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Update transactions in database
      for (final tx in transactionsToMove) {
        final updatedTx = tx.copyWith(accountId: toAccountId);
        await repo.updateTransaction(updatedTx);
      }

      // Update account balances:
      // Remove the effect from source account (reverse it)
      await ref.read(accountsProvider.notifier).updateBalance(fromAccountId, -totalEffect);
      // Add the effect to target account
      await ref.read(accountsProvider.notifier).updateBalance(toAccountId, totalEffect);
    });

    // Update local state for transactions
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
    final db = ref.read(databaseProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final transactionsToDelete = currentState.where((t) => t.accountId == accountId).toList();

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      for (final tx in transactionsToDelete) {
        await repo.deleteTransaction(tx.id);
      }
    });

    // Update local state
    state = state.whenData(
      (transactions) => transactions.where((t) => t.accountId != accountId).toList(),
    );
  }

  /// Move all transactions from one category to another
  Future<void> moveTransactionsToCategory(String fromCategoryId, String toCategoryId) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final transactionsToMove = currentState.where((t) => t.categoryId == fromCategoryId).toList();

    if (transactionsToMove.isEmpty) return;

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Update transactions in database
      for (final tx in transactionsToMove) {
        final updatedTx = tx.copyWith(categoryId: toCategoryId);
        await repo.updateTransaction(updatedTx);
      }
    });

    // Update local state for transactions
    state = state.whenData(
      (transactions) => transactions.map((t) {
        if (t.categoryId == fromCategoryId) {
          return t.copyWith(categoryId: toCategoryId);
        }
        return t;
      }).toList(),
    );
  }

  /// Delete all transactions for a specific category and reverse account balances
  Future<void> deleteTransactionsForCategory(String categoryId) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final transactionsToDelete = currentState.where((t) => t.categoryId == categoryId).toList();

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Delete each transaction and reverse its balance effect
      for (final tx in transactionsToDelete) {
        await repo.deleteTransaction(tx.id);

        // Reverse the balance change
        final balanceChange =
            tx.type == TransactionType.income ? -tx.amount : tx.amount;
        await ref.read(accountsProvider.notifier).updateBalance(
              tx.accountId,
              balanceChange,
            );
      }
    });

    // Update local state
    state = state.whenData(
      (transactions) => transactions.where((t) => t.categoryId != categoryId).toList(),
    );
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

final deletedTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAllDeletedTransactions();
});

enum TransactionFilter { all, income, expense, transfer }

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
      case TransactionFilter.transfer:
        return transactions.where((t) => t.type == TransactionType.transfer).toList();
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

final transactionDateBoundsProvider = Provider<({DateTime? earliest, DateTime? latest})>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (transactions == null || transactions.isEmpty) {
    return (earliest: null, latest: null);
  }
  DateTime earliest = transactions.first.date;
  DateTime latest = transactions.first.date;
  for (final tx in transactions) {
    if (tx.date.isBefore(earliest)) earliest = tx.date;
    if (tx.date.isAfter(latest)) latest = tx.date;
  }
  return (earliest: earliest, latest: latest);
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
  return transactions
      .where((t) => t.accountId == accountId || t.destinationAccountId == accountId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final transactionCountByAccountProvider = Provider.family<int, String>((ref, accountId) {
  return ref.watch(transactionsByAccountProvider(accountId)).length;
});

final transactionsByCategoryProvider = Provider.family<List<Transaction>, String>((ref, categoryId) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (transactions == null) return [];
  return transactions.where((t) => t.categoryId == categoryId).toList();
});

final transactionCountByCategoryProvider = Provider.family<int, String>((ref, categoryId) {
  return ref.watch(transactionsByCategoryProvider(categoryId)).length;
});

final searchedTransactionsProvider = Provider<AsyncValue<List<TransactionGroup>>>((ref) {
  final groupsAsync = ref.watch(groupedTransactionsProvider);
  final query = ref.watch(transactionSearchQueryProvider).toLowerCase();

  return groupsAsync.whenData((groups) {
    if (query.isEmpty) return groups;

    return groups.map((group) {
      final filteredTxs = group.transactions.where((tx) {
        final note = tx.note?.toLowerCase() ?? '';
        final merchant = tx.merchant?.toLowerCase() ?? '';
        return note.contains(query) || merchant.contains(query);
      }).toList();

      return TransactionGroup(date: group.date, transactions: filteredTxs);
    }).where((group) => group.transactions.isNotEmpty).toList();
  });
});

/// Provides distinct merchant names from transaction history, sorted by frequency.
final merchantSuggestionsProvider = Provider<List<String>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (transactions == null) return [];

  final frequency = <String, int>{};
  for (final tx in transactions) {
    final merchant = tx.merchant?.trim();
    if (merchant != null && merchant.isNotEmpty) {
      frequency[merchant] = (frequency[merchant] ?? 0) + 1;
    }
  }

  final sorted = frequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => e.key).toList();
});
