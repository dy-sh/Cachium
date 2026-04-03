import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/balance_calculation.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/advanced_transaction_filter.dart';
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
    String? assetId,
    bool isAcquisitionCost = false,
    String currencyCode = 'USD',
    double conversionRate = 1.0,
    double? destinationAmount,
    String mainCurrencyCode = 'USD',
    double? mainCurrencyAmount,
    required DateTime date,
    String? note,
    String? merchant,
  }) async {
    if (conversionRate <= 0 || !conversionRate.isFinite) {
      throw ValidationException.outOfRange('conversionRate', min: 0);
    }

    // Validate referenced entities exist
    if (ref.read(accountByIdProvider(accountId)) == null) {
      throw EntityNotFoundException(entityType: 'Account', entityId: accountId);
    }
    if (ref.read(categoryByIdProvider(categoryId)) == null) {
      throw EntityNotFoundException(entityType: 'Category', entityId: categoryId);
    }

    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);

    final effectiveMainCurrencyAmount = mainCurrencyAmount ??
        (currencyCode == mainCurrencyCode
            ? amount
            : roundCurrency(amount * conversionRate));

    final transaction = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      destinationAccountId: destinationAccountId,
      assetId: assetId,
      isAcquisitionCost: isAcquisitionCost,
      currencyCode: currencyCode,
      conversionRate: conversionRate,
      destinationAmount: destinationAmount,
      mainCurrencyCode: mainCurrencyCode,
      mainCurrencyAmount: effectiveMainCurrencyAmount,
      date: date,
      note: note,
      merchant: merchant,
      createdAt: DateTime.now(),
    );

    // Capture account state before entering transaction to avoid race conditions
    if (type == TransactionType.transfer && destinationAccountId != null) {
      final srcAccount = ref.read(accountByIdProvider(accountId));
      final dstAccount = ref.read(accountByIdProvider(destinationAccountId));
      if (destinationAmount == null &&
          srcAccount != null && dstAccount != null &&
          srcAccount.currencyCode != dstAccount.currencyCode) {
        throw ValidationException(
          message: 'Cross-currency transfer requires destinationAmount',
          field: 'destinationAmount',
          rule: 'required',
        );
      }
    }

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Save to encrypted database
      await repo.createTransaction(transaction);

      // Update account balances
      for (final entry in transactionDeltas(transaction).entries) {
        await ref.read(accountsProvider.notifier).updateBalance(entry.key, entry.value);
      }
    });

    // Update local state
    state = state.whenData((transactions) => [transaction, ...transactions]);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    // Validate referenced entities exist
    if (ref.read(accountByIdProvider(transaction.accountId)) == null) {
      throw EntityNotFoundException(entityType: 'Account', entityId: transaction.accountId);
    }
    if (ref.read(categoryByIdProvider(transaction.categoryId)) == null) {
      throw EntityNotFoundException(entityType: 'Category', entityId: transaction.categoryId);
    }

    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);

    // Get original transaction to calculate balance difference
    final currentState = state.valueOrNull;
    if (currentState == null) {
      throw RepositoryException.fetch(entityType: 'Transaction');
    }

    final index = currentState.indexWhere((t) => t.id == transaction.id);
    if (index == -1) {
      throw EntityNotFoundException(entityType: 'Transaction', entityId: transaction.id);
    }
    final originalTransaction = currentState[index];

    // Validate cross-currency transfer before entering transaction
    if (transaction.type == TransactionType.transfer &&
        transaction.destinationAccountId != null) {
      final srcAcct = ref.read(accountByIdProvider(transaction.accountId));
      final dstAcct = ref.read(accountByIdProvider(transaction.destinationAccountId!));
      if (transaction.destinationAmount == null &&
          srcAcct != null && dstAcct != null &&
          srcAcct.currencyCode != dstAcct.currencyCode) {
        throw ValidationException(
          message: 'Cross-currency transfer requires destinationAmount',
          field: 'destinationAmount',
          rule: 'required',
        );
      }
    }

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Reverse original balance effects
      for (final entry in reverseTransactionDeltas(originalTransaction).entries) {
        await ref.read(accountsProvider.notifier).updateBalance(entry.key, entry.value);
      }

      // Apply new balance effects
      for (final entry in transactionDeltas(transaction).entries) {
        await ref.read(accountsProvider.notifier).updateBalance(entry.key, entry.value);
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
    if (currentState == null) {
      throw RepositoryException.fetch(entityType: 'Transaction');
    }

    final deleteIndex = currentState.indexWhere((t) => t.id == id);
    if (deleteIndex == -1) {
      throw EntityNotFoundException(entityType: 'Transaction', entityId: id);
    }
    final transaction = currentState[deleteIndex];

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Soft delete in database
      await repo.deleteTransaction(id);

      // Clean up related attachments and tag associations
      await ref.read(attachmentRepositoryProvider).deleteAttachmentsForTransaction(id);
      await ref.read(tagRepositoryProvider).removeTagsForTransaction(id);

      // Reverse the balance change
      for (final entry in reverseTransactionDeltas(transaction).entries) {
        await ref.read(accountsProvider.notifier).updateBalance(entry.key, entry.value);
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

    // Validate referenced accounts still exist
    final sourceAccount = ref.read(accountByIdProvider(transaction.accountId));
    if (sourceAccount == null) {
      throw EntityNotFoundException(
        entityType: 'Account',
        entityId: transaction.accountId,
      );
    }
    if (transaction.type == TransactionType.transfer &&
        transaction.destinationAccountId != null) {
      final destAccount = ref.read(accountByIdProvider(transaction.destinationAccountId!));
      if (destAccount == null) {
        throw EntityNotFoundException(
          entityType: 'Account',
          entityId: transaction.destinationAccountId!,
        );
      }
    }

    await db.transaction(() async {
      // Restore in database
      await repo.restoreTransaction(transaction.id);

      // Re-apply the balance change to the account
      for (final entry in transactionDeltas(transaction).entries) {
        await ref.read(accountsProvider.notifier).updateBalance(entry.key, entry.value);
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
    if (currentState == null) {
      throw RepositoryException.fetch(entityType: 'Transaction');
    }

    await db.transaction(() async {
      for (final id in ids) {
        final batchIndex = currentState.indexWhere((t) => t.id == id);
        if (batchIndex == -1) {
          throw EntityNotFoundException(entityType: 'Transaction', entityId: id);
        }
        final transaction = currentState[batchIndex];
        await repo.deleteTransaction(id);

        // Clean up related attachments and tag associations
        await ref.read(attachmentRepositoryProvider).deleteAttachmentsForTransaction(id);
        await ref.read(tagRepositoryProvider).removeTagsForTransaction(id);

        // Reverse the balance change
        for (final entry in reverseTransactionDeltas(transaction).entries) {
          await ref.read(accountsProvider.notifier).updateBalance(entry.key, entry.value);
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

    // Validate all referenced accounts still exist before starting
    for (final transaction in transactionsToRestore) {
      final sourceAccount = ref.read(accountByIdProvider(transaction.accountId));
      if (sourceAccount == null) {
        throw EntityNotFoundException(
          entityType: 'Account',
          entityId: transaction.accountId,
        );
      }
      if (transaction.type == TransactionType.transfer &&
          transaction.destinationAccountId != null) {
        final destAccount = ref.read(accountByIdProvider(transaction.destinationAccountId!));
        if (destAccount == null) {
          throw EntityNotFoundException(
            entityType: 'Account',
            entityId: transaction.destinationAccountId!,
          );
        }
      }
    }

    await db.transaction(() async {
      for (final transaction in transactionsToRestore) {
        await repo.restoreTransaction(transaction.id);

        // Re-apply the balance change
        for (final entry in transactionDeltas(transaction).entries) {
          await ref.read(accountsProvider.notifier).updateBalance(entry.key, entry.value);
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
    if (currentState == null) {
      throw RepositoryException.fetch(entityType: 'Transaction');
    }

    final transactionsToMove = currentState.where((t) => t.accountId == fromAccountId).toList();

    if (transactionsToMove.isEmpty) return;

    // Get account currencies for cross-currency conversion
    final fromAccount = ref.read(accountByIdProvider(fromAccountId));
    final toAccount = ref.read(accountByIdProvider(toAccountId));
    final isCrossCurrency = fromAccount != null && toAccount != null &&
        fromAccount.currencyCode != toAccount.currencyCode;

    // Get exchange rate if cross-currency
    double crossRate = 1.0;
    if (isCrossCurrency) {
      crossRate = ref.read(exchangeRateProvider((
        from: fromAccount.currencyCode,
        to: toAccount.currencyCode,
      )));
    }

    // Calculate total balance effect on source account (in source currency)
    // and prepare updated transactions
    double sourceEffect = 0;
    double destEffect = 0;
    final updatedTransactions = <Transaction>[];

    for (final tx in transactionsToMove) {
      final sign = tx.type == TransactionType.income ? 1.0 : -1.0;
      // For transfers, the source debit was -amount (already applied)
      if (tx.type == TransactionType.transfer) {
        sourceEffect -= tx.amount; // Source was debited by -amount
      } else {
        sourceEffect += sign * tx.amount;
      }

      if (isCrossCurrency) {
        // Convert amount to destination currency
        final convertedAmount = roundCurrency(tx.amount * crossRate);
        final convertedDestAmount = tx.destinationAmount != null
            ? roundCurrency(tx.destinationAmount! * crossRate)
            : null;

        if (tx.type == TransactionType.transfer) {
          destEffect -= convertedAmount;
        } else {
          destEffect += sign * convertedAmount;
        }

        // Recalculate conversionRate for cross-currency move, but preserve historical mainCurrency snapshot
        final mainCurrency = ref.read(mainCurrencyCodeProvider);
        final rates = ref.read(exchangeRatesProvider).valueOrNull ?? {};
        final newConversionRate = (toAccount.currencyCode != mainCurrency && rates[toAccount.currencyCode] != null)
            ? 1.0 / rates[toAccount.currencyCode]!
            : tx.conversionRate;
        updatedTransactions.add(tx.copyWith(
          accountId: toAccountId,
          amount: convertedAmount,
          currencyCode: toAccount.currencyCode,
          conversionRate: newConversionRate,
          destinationAmount: convertedDestAmount,
          mainCurrencyCode: tx.mainCurrencyCode,
          mainCurrencyAmount: tx.mainCurrencyAmount,
        ));
      } else {
        if (tx.type == TransactionType.transfer) {
          destEffect -= tx.amount;
        } else {
          destEffect += sign * tx.amount;
        }
        updatedTransactions.add(tx.copyWith(accountId: toAccountId));
      }
    }

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Update transactions in database
      for (final tx in updatedTransactions) {
        await repo.updateTransaction(tx);
      }

      // Update account balances:
      // Remove the effect from source account (reverse it)
      await ref.read(accountsProvider.notifier).updateBalance(fromAccountId, -sourceEffect);
      // Add the effect to target account
      await ref.read(accountsProvider.notifier).updateBalance(toAccountId, destEffect);
    });

    // Update local state for transactions
    final updatedMap = {for (final tx in updatedTransactions) tx.id: tx};
    state = state.whenData(
      (transactions) => transactions.map((t) {
        return updatedMap[t.id] ?? t;
      }).toList(),
    );
  }

  /// Delete all transactions for a specific account and reverse balance effects
  Future<void> deleteTransactionsForAccount(String accountId) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) {
      throw RepositoryException.fetch(entityType: 'Transaction');
    }

    // Find transactions where this account is the source
    final sourceTransactions = currentState.where((t) => t.accountId == accountId).toList();
    // Find transactions where this account is the transfer destination
    final destTransactions = currentState.where(
      (t) => t.destinationAccountId == accountId && t.accountId != accountId,
    ).toList();

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Delete source transactions and reverse their balance effects
      for (final tx in sourceTransactions) {
        await repo.deleteTransaction(tx.id);
        await ref.read(attachmentRepositoryProvider).deleteAttachmentsForTransaction(tx.id);
        await ref.read(tagRepositoryProvider).removeTagsForTransaction(tx.id);

        // Reverse the balance change on linked accounts
        if (tx.type == TransactionType.transfer && tx.destinationAccountId != null &&
            tx.destinationAccountId != accountId) {
          // This account is source of a transfer — reverse the credit on destination
          await ref.read(accountsProvider.notifier).updateBalance(
                tx.destinationAccountId!, -(tx.destinationAmount ?? tx.amount));
        }
      }

      // For transfers where this account is the destination, reverse the debit on source and soft-delete
      for (final tx in destTransactions) {
        // Reverse the debit from source account (transfer debits source by tx.amount)
        await ref.read(accountsProvider.notifier).updateBalance(
              tx.accountId, tx.amount);
        await repo.deleteTransaction(tx.id);
        await ref.read(attachmentRepositoryProvider).deleteAttachmentsForTransaction(tx.id);
        await ref.read(tagRepositoryProvider).removeTagsForTransaction(tx.id);
      }
    });

    // Update local state — remove transactions where this account is source or destination
    final destIds = destTransactions.map((t) => t.id).toSet();
    state = state.whenData(
      (transactions) => transactions.where(
        (t) => t.accountId != accountId && !destIds.contains(t.id),
      ).toList(),
    );
  }

  /// Move all transactions from one category to another
  Future<void> moveTransactionsToCategory(String fromCategoryId, String toCategoryId) async {
    final repo = ref.read(transactionRepositoryProvider);
    final db = ref.read(databaseProvider);
    final currentState = state.valueOrNull;
    if (currentState == null) {
      throw RepositoryException.fetch(entityType: 'Transaction');
    }

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
    if (currentState == null) {
      throw RepositoryException.fetch(entityType: 'Transaction');
    }

    final transactionsToDelete = currentState.where((t) => t.categoryId == categoryId).toList();

    // Wrap in database transaction to prevent locking issues
    await db.transaction(() async {
      // Delete each transaction and reverse its balance effect
      for (final tx in transactionsToDelete) {
        await repo.deleteTransaction(tx.id);
        await ref.read(attachmentRepositoryProvider).deleteAttachmentsForTransaction(tx.id);
        await ref.read(tagRepositoryProvider).removeTagsForTransaction(tx.id);

        // Reverse the balance change
        for (final entry in reverseTransactionDeltas(tx).entries) {
          await ref.read(accountsProvider.notifier).updateBalance(entry.key, entry.value);
        }
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

class AdvancedTransactionFilterNotifier extends Notifier<AdvancedTransactionFilter> {
  @override
  AdvancedTransactionFilter build() => const AdvancedTransactionFilter();

  void setAmountRange({double? min, double? max}) {
    state = state.copyWith(
      minAmount: min,
      clearMinAmount: min == null,
      maxAmount: max,
      clearMaxAmount: max == null,
    );
  }

  void setDateRange({DateTime? start, DateTime? end}) {
    state = state.copyWith(
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
    );
  }

  void toggleCategory(String categoryId) {
    final current = Set<String>.from(state.selectedCategoryIds);
    if (current.contains(categoryId)) {
      current.remove(categoryId);
    } else {
      current.add(categoryId);
    }
    state = state.copyWith(selectedCategoryIds: current);
  }

  void setCategories(Set<String> ids) {
    state = state.copyWith(selectedCategoryIds: ids);
  }

  void toggleAccount(String accountId) {
    final current = Set<String>.from(state.selectedAccountIds);
    if (current.contains(accountId)) {
      current.remove(accountId);
    } else {
      current.add(accountId);
    }
    state = state.copyWith(selectedAccountIds: current);
  }

  void setAccounts(Set<String> ids) {
    state = state.copyWith(selectedAccountIds: ids);
  }

  void clearAll() {
    state = const AdvancedTransactionFilter();
  }
}

final advancedTransactionFilterProvider =
    NotifierProvider<AdvancedTransactionFilterNotifier, AdvancedTransactionFilter>(() {
  return AdvancedTransactionFilterNotifier();
});

final activeFilterCountProvider = Provider<int>((ref) {
  return ref.watch(advancedTransactionFilterProvider).activeFilterCount;
});

final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);
  final advanced = ref.watch(advancedTransactionFilterProvider);

  return transactionsAsync.whenData((transactions) {
    var result = transactions;

    // Type filter
    switch (filter) {
      case TransactionFilter.income:
        result = result.where((t) => t.type == TransactionType.income).toList();
      case TransactionFilter.expense:
        result = result.where((t) => t.type == TransactionType.expense).toList();
      case TransactionFilter.transfer:
        result = result.where((t) => t.type == TransactionType.transfer).toList();
      case TransactionFilter.all:
        break;
    }

    // Advanced filters
    if (advanced.isActive) {
      result = result.where((t) {
        if (advanced.minAmount != null && t.amount < advanced.minAmount!) return false;
        if (advanced.maxAmount != null && t.amount > advanced.maxAmount!) return false;
        if (advanced.startDate != null && t.date.isBefore(advanced.startDate!)) return false;
        if (advanced.endDate != null) {
          final endOfDay = DateTime(advanced.endDate!.year, advanced.endDate!.month, advanced.endDate!.day, 23, 59, 59);
          if (t.date.isAfter(endOfDay)) return false;
        }
        if (advanced.selectedCategoryIds.isNotEmpty && !advanced.selectedCategoryIds.contains(t.categoryId)) return false;
        if (advanced.selectedAccountIds.isNotEmpty && !advanced.selectedAccountIds.contains(t.accountId)) return false;
        return true;
      }).toList();
    }

    return result;
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

/// Indexed map of all transactions by ID for O(1) lookups.
final transactionMapProvider = Provider<Map<String, Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (transactions == null) return {};
  return {for (final t in transactions) t.id: t};
});

final transactionByIdProvider = Provider.autoDispose.family<Transaction?, String>((ref, id) {
  return ref.watch(transactionMapProvider)[id];
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

/// Number of transactions to show per page.
const _transactionPageSize = 50;

/// Controls how many transactions are currently displayed.
/// Incremented by [loadMoreTransactions] when the user scrolls to the bottom.
final transactionDisplayCountProvider = StateProvider<int>((ref) {
  // Reset when the underlying data changes (search, filter, etc.)
  ref.watch(searchedTransactionsProvider);
  return _transactionPageSize;
});

/// Whether more transactions are available beyond the current display count.
final hasMoreTransactionsProvider = Provider<bool>((ref) {
  final displayCount = ref.watch(transactionDisplayCountProvider);
  final groups = ref.watch(searchedTransactionsProvider).valueOrNull ?? [];
  final totalCount = groups.fold<int>(0, (sum, g) => sum + g.transactions.length);
  return displayCount < totalCount;
});

/// Paginated transaction groups: only includes enough groups to fill
/// [transactionDisplayCountProvider] transactions.
final paginatedTransactionsProvider = Provider<AsyncValue<List<TransactionGroup>>>((ref) {
  final groupsAsync = ref.watch(searchedTransactionsProvider);
  final displayCount = ref.watch(transactionDisplayCountProvider);

  return groupsAsync.whenData((groups) {
    int remaining = displayCount;
    final result = <TransactionGroup>[];

    for (final group in groups) {
      if (remaining <= 0) break;

      if (group.transactions.length <= remaining) {
        result.add(group);
        remaining -= group.transactions.length;
      } else {
        // Partial group: take only the first `remaining` transactions
        result.add(TransactionGroup(
          date: group.date,
          transactions: group.transactions.sublist(0, remaining),
        ));
        remaining = 0;
      }
    }

    return result;
  });
});

final transactionsByAssetProvider = Provider.family<List<Transaction>, String>((ref, assetId) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (transactions == null) return [];
  return transactions.where((t) => t.assetId == assetId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

/// Maps lowercase merchant names to their most frequently used category ID.
/// Excludes transfers. Used for auto-categorization.
final merchantCategoryMapProvider = Provider<Map<String, String>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (transactions == null) return {};

  // Count category usage per merchant
  final merchantCategoryCounts = <String, Map<String, int>>{};
  for (final tx in transactions) {
    if (tx.type == TransactionType.transfer) continue;
    final merchant = tx.merchant?.trim().toLowerCase();
    if (merchant == null || merchant.isEmpty) continue;
    final categoryId = tx.categoryId;
    if (categoryId.isEmpty) continue;

    merchantCategoryCounts.putIfAbsent(merchant, () => {});
    merchantCategoryCounts[merchant]![categoryId] =
        (merchantCategoryCounts[merchant]![categoryId] ?? 0) + 1;
  }

  // Pick the most frequent category for each merchant
  final result = <String, String>{};
  for (final entry in merchantCategoryCounts.entries) {
    final counts = entry.value;
    String? bestId;
    int bestCount = 0;
    for (final catEntry in counts.entries) {
      if (catEntry.value > bestCount) {
        bestCount = catEntry.value;
        bestId = catEntry.key;
      }
    }
    if (bestId != null) {
      result[entry.key] = bestId;
    }
  }

  return result;
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
