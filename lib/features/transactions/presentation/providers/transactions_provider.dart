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
import '../../data/models/transaction.dart';

// Re-export the derived query/filter/search providers so existing callers
// that `import 'transactions_provider.dart'` keep working after the split.
export 'transaction_queries.dart';

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
        throw const ValidationException(
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
        throw const ValidationException(
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

