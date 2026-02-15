import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/transactions/data/models/transaction.dart' as ui;
import '../encryption/transaction_data.dart';

/// Repository for managing encrypted transaction storage.
///
/// Converts between UI Transaction models and encrypted database records.
/// All sensitive data is encrypted before storage and decrypted on retrieval.
///
/// Error Handling:
/// - Throws [RepositoryException] for database/encryption failures
/// - Throws [EntityNotFoundException] when requested entity doesn't exist
/// - Returns null from getTransaction() if not found (for optional lookups)
class TransactionRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'Transaction';

  TransactionRepository({
    required this.database,
    required this.encryptionService,
  });

  /// Convert UI Transaction to internal TransactionData for encryption
  TransactionData _toData(ui.Transaction transaction) {
    return TransactionData(
      id: transaction.id,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      type: transaction.type.name, // 'income', 'expense', or 'transfer'
      note: transaction.note,
      merchant: transaction.merchant,
      destinationAccountId: transaction.destinationAccountId,
      currency: 'USD', // Default for now
      dateMillis: transaction.date.millisecondsSinceEpoch,
      createdAtMillis: transaction.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Convert internal TransactionData to UI Transaction
  ui.Transaction _toTransaction(TransactionData data) {
    return ui.Transaction(
      id: data.id,
      amount: data.amount,
      type: ui.TransactionType.values.firstWhere(
        (e) => e.name == data.type,
        orElse: () => ui.TransactionType.expense,
      ),
      categoryId: data.categoryId,
      accountId: data.accountId,
      destinationAccountId: data.destinationAccountId,
      date: DateTime.fromMillisecondsSinceEpoch(data.dateMillis),
      note: data.note,
      merchant: data.merchant,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  /// Create a new transaction (encrypt and insert)
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> createTransaction(ui.Transaction transaction) async {
    try {
      final data = _toData(transaction);
      final encryptedBlob = await encryptionService.encrypt(data);

      await database.insertTransaction(
        id: transaction.id,
        date: transaction.date.millisecondsSinceEpoch,
        lastUpdatedAt: transaction.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Create or update a transaction (encrypt and upsert)
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> upsertTransaction(ui.Transaction transaction) async {
    try {
      final data = _toData(transaction);
      final encryptedBlob = await encryptionService.encrypt(data);

      await database.upsertTransaction(
        id: transaction.id,
        date: transaction.date.millisecondsSinceEpoch,
        lastUpdatedAt: transaction.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Create or update a transaction with raw sync metadata.
  ///
  /// Use this for imports that need to preserve sync-critical fields like
  /// lastUpdatedAt and currency from the source data.
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> upsertTransactionRaw(
    ui.Transaction transaction, {
    int? lastUpdatedAt,
    bool isDeleted = false,
    String currency = 'USD',
  }) async {
    try {
      final data = TransactionData(
        id: transaction.id,
        amount: transaction.amount,
        categoryId: transaction.categoryId,
        accountId: transaction.accountId,
        type: transaction.type.name,
        note: transaction.note,
        merchant: transaction.merchant,
        currency: currency,
        dateMillis: transaction.date.millisecondsSinceEpoch,
        createdAtMillis: transaction.createdAt.millisecondsSinceEpoch,
      );
      final encryptedBlob = await encryptionService.encrypt(data);

      final effectiveLastUpdatedAt = lastUpdatedAt ?? DateTime.now().millisecondsSinceEpoch;

      await database.upsertTransaction(
        id: transaction.id,
        date: transaction.date.millisecondsSinceEpoch,
        lastUpdatedAt: effectiveLastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: isDeleted,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Get a single transaction by ID (fetch, decrypt, verify)
  ///
  /// Returns null if transaction doesn't exist.
  /// Throws [RepositoryException] if decryption fails.
  Future<ui.Transaction?> getTransaction(String id) async {
    final row = await database.getTransaction(id);
    if (row == null) return null;

    try {
      final data = await encryptionService.decrypt(
        row.encryptedBlob,
        expectedId: row.id,
        expectedDateMillis: row.date,
      );
      return _toTransaction(data);
    } catch (e) {
      throw RepositoryException.decryption(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  /// Get a single transaction by ID, throwing if not found.
  ///
  /// Throws [EntityNotFoundException] if transaction doesn't exist.
  /// Throws [RepositoryException] if decryption fails.
  Future<ui.Transaction> getTransactionOrThrow(String id) async {
    final transaction = await getTransaction(id);
    if (transaction == null) {
      throw EntityNotFoundException(entityType: _entityType, entityId: id);
    }
    return transaction;
  }

  /// Get all non-deleted transactions
  ///
  /// Throws [RepositoryException] if fetch or decryption fails.
  Future<List<ui.Transaction>> getAllTransactions() async {
    try {
      final rows = await database.getAllTransactions();
      final transactions = <ui.Transaction>[];

      for (final row in rows) {
        final data = await encryptionService.decrypt(
          row.encryptedBlob,
          expectedId: row.id,
          expectedDateMillis: row.date,
        );
        transactions.add(_toTransaction(data));
      }

      return transactions;
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  /// Get all soft-deleted transactions
  ///
  /// Throws [RepositoryException] if fetch or decryption fails.
  Future<List<ui.Transaction>> getAllDeletedTransactions() async {
    try {
      final rows = await database.getAllDeletedTransactions();
      final transactions = <ui.Transaction>[];

      for (final row in rows) {
        try {
          final data = await encryptionService.decrypt(
            row.encryptedBlob,
            expectedId: row.id,
            expectedDateMillis: row.date,
          );
          transactions.add(_toTransaction(data));
        } catch (_) {
          // Skip corrupted rows
          continue;
        }
      }

      return transactions;
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  /// Update an existing transaction (re-encrypt and update)
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> updateTransaction(ui.Transaction transaction) async {
    try {
      final data = _toData(transaction);
      final encryptedBlob = await encryptionService.encrypt(data);

      await database.updateTransaction(
        id: transaction.id,
        date: transaction.date.millisecondsSinceEpoch,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.update(
        entityType: _entityType,
        entityId: transaction.id,
        cause: e,
      );
    }
  }

  /// Soft delete a transaction (set isDeleted = true)
  ///
  /// Throws [RepositoryException] if database operation fails.
  Future<void> deleteTransaction(String id) async {
    try {
      await database.softDeleteTransaction(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw RepositoryException.delete(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  /// Restore a soft-deleted transaction (set isDeleted = false)
  ///
  /// Throws [RepositoryException] if database operation fails.
  Future<void> restoreTransaction(String id) async {
    try {
      await database.restoreTransaction(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw RepositoryException.update(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  /// Watch all transactions (for reactive UI)
  ///
  /// Note: Each emission triggers decryption of all rows.
  /// For large datasets, consider pagination or caching.
  /// Corrupted rows are silently skipped to maintain stream stability.
  Stream<List<ui.Transaction>> watchAllTransactions() {
    return database.watchAllTransactions().asyncMap((rows) async {
      final transactions = <ui.Transaction>[];

      for (final row in rows) {
        try {
          final data = await encryptionService.decrypt(
            row.encryptedBlob,
            expectedId: row.id,
            expectedDateMillis: row.date,
          );
          transactions.add(_toTransaction(data));
        } catch (_) {
          // Skip corrupted rows in stream to maintain stability
          continue;
        }
      }

      return transactions;
    });
  }

  /// Check if any transactions exist in the database
  Future<bool> hasTransactions() async {
    return database.hasTransactions();
  }
}
