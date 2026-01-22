import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../features/transactions/data/models/transaction.dart' as ui;
import '../models/transaction_data.dart';

/// Repository for managing encrypted transaction storage.
///
/// Converts between UI Transaction models and encrypted database records.
/// All sensitive data is encrypted before storage and decrypted on retrieval.
class TransactionRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

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
      type: transaction.type.name, // 'income' or 'expense'
      note: transaction.note,
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
      type: data.type == 'income'
          ? ui.TransactionType.income
          : ui.TransactionType.expense,
      categoryId: data.categoryId,
      accountId: data.accountId,
      date: DateTime.fromMillisecondsSinceEpoch(data.dateMillis),
      note: data.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  /// Create a new transaction (encrypt and insert)
  Future<void> createTransaction(ui.Transaction transaction) async {
    final data = _toData(transaction);
    final encryptedBlob = await encryptionService.encrypt(data);

    await database.insertTransaction(
      id: transaction.id,
      date: transaction.date.millisecondsSinceEpoch,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Create or update a transaction (encrypt and upsert)
  Future<void> upsertTransaction(ui.Transaction transaction) async {
    final data = _toData(transaction);
    final encryptedBlob = await encryptionService.encrypt(data);

    await database.upsertTransaction(
      id: transaction.id,
      date: transaction.date.millisecondsSinceEpoch,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Get a single transaction by ID (fetch, decrypt, verify)
  Future<ui.Transaction?> getTransaction(String id) async {
    final row = await database.getTransaction(id);
    if (row == null) return null;

    final data = await encryptionService.decrypt(
      row.encryptedBlob,
      expectedId: row.id,
      expectedDateMillis: row.date,
    );

    return _toTransaction(data);
  }

  /// Get all non-deleted transactions
  Future<List<ui.Transaction>> getAllTransactions() async {
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
  }

  /// Update an existing transaction (re-encrypt and update)
  Future<void> updateTransaction(ui.Transaction transaction) async {
    final data = _toData(transaction);
    final encryptedBlob = await encryptionService.encrypt(data);

    await database.updateTransaction(
      id: transaction.id,
      date: transaction.date.millisecondsSinceEpoch,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Soft delete a transaction (set isDeleted = true)
  Future<void> deleteTransaction(String id) async {
    await database.softDeleteTransaction(
      id,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Watch all transactions (for reactive UI)
  ///
  /// Note: Each emission triggers decryption of all rows.
  /// For large datasets, consider pagination or caching.
  Stream<List<ui.Transaction>> watchAllTransactions() {
    return database.watchAllTransactions().asyncMap((rows) async {
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
    });
  }

  /// Check if any transactions exist in the database
  Future<bool> hasTransactions() async {
    return database.hasTransactions();
  }
}
