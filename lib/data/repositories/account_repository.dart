import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/accounts/data/models/account.dart' as ui;
import '../encryption/account_data.dart';

/// Repository for managing encrypted account storage.
///
/// Converts between UI Account models and encrypted database records.
/// All sensitive data is encrypted before storage and decrypted on retrieval.
///
/// Error Handling:
/// - Throws [RepositoryException] for database/encryption failures
/// - Throws [EntityNotFoundException] when requested entity doesn't exist
/// - Returns null from getAccount() if not found (for optional lookups)
class AccountRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'Account';

  AccountRepository({
    required this.database,
    required this.encryptionService,
  });

  /// Convert UI Account to internal AccountData for encryption
  AccountData _toData(ui.Account account) {
    return AccountData(
      id: account.id,
      name: account.name,
      type: account.type.name,
      balance: account.balance,
      initialBalance: account.initialBalance,
      customColorValue: account.customColor?.toARGB32(),
      customIconCodePoint: account.customIcon?.codePoint,
      createdAtMillis: account.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Convert internal AccountData to UI Account
  ui.Account _toAccount(AccountData data) {
    return ui.Account(
      id: data.id,
      name: data.name,
      type: ui.AccountType.values.firstWhere(
        (t) => t.name == data.type,
        orElse: () => ui.AccountType.bank,
      ),
      balance: data.balance,
      initialBalance: data.initialBalance,
      customColor: data.customColorValue != null
          ? Color(data.customColorValue!)
          : null,
      customIcon: data.customIconCodePoint != null
          ? IconData(data.customIconCodePoint!, fontFamily: 'MaterialIcons')
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  /// Create a new account (encrypt and insert)
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> createAccount(ui.Account account) async {
    try {
      final data = _toData(account);
      final encryptedBlob = await encryptionService.encryptAccount(data);

      await database.insertAccount(
        id: account.id,
        createdAt: account.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: account.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Create or update an account (encrypt and upsert)
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> upsertAccount(ui.Account account) async {
    try {
      final data = _toData(account);
      final encryptedBlob = await encryptionService.encryptAccount(data);

      await database.upsertAccount(
        id: account.id,
        createdAt: account.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: account.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Get a single account by ID (fetch, decrypt, verify)
  ///
  /// Returns null if account doesn't exist.
  /// Throws [RepositoryException] if decryption fails.
  Future<ui.Account?> getAccount(String id) async {
    final row = await database.getAccount(id);
    if (row == null) return null;

    try {
      final data = await encryptionService.decryptAccount(
        row.encryptedBlob,
        expectedId: row.id,
        expectedCreatedAtMillis: row.createdAt,
      );
      return _toAccount(data);
    } catch (e) {
      throw RepositoryException.decryption(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  /// Get a single account by ID, throwing if not found.
  ///
  /// Throws [EntityNotFoundException] if account doesn't exist.
  /// Throws [RepositoryException] if decryption fails.
  Future<ui.Account> getAccountOrThrow(String id) async {
    final account = await getAccount(id);
    if (account == null) {
      throw EntityNotFoundException(entityType: _entityType, entityId: id);
    }
    return account;
  }

  /// Get all non-deleted accounts
  ///
  /// Throws [RepositoryException] if fetch or decryption fails.
  Future<List<ui.Account>> getAllAccounts() async {
    try {
      final rows = await database.getAllAccounts();
      final accounts = <ui.Account>[];

      for (final row in rows) {
        final data = await encryptionService.decryptAccount(
          row.encryptedBlob,
          expectedId: row.id,
          expectedCreatedAtMillis: row.createdAt,
        );
        accounts.add(_toAccount(data));
      }

      return accounts;
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  /// Update an existing account (re-encrypt and update)
  ///
  /// Throws [RepositoryException] if encryption or database operation fails.
  Future<void> updateAccount(ui.Account account) async {
    try {
      final data = _toData(account);
      final encryptedBlob = await encryptionService.encryptAccount(data);

      await database.updateAccount(
        id: account.id,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.update(
        entityType: _entityType,
        entityId: account.id,
        cause: e,
      );
    }
  }

  /// Soft delete an account (set isDeleted = true)
  ///
  /// Throws [RepositoryException] if database operation fails.
  Future<void> deleteAccount(String id) async {
    try {
      await database.softDeleteAccount(
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

  /// Watch all accounts (for reactive UI)
  ///
  /// Note: Each emission triggers decryption of all rows.
  /// For large datasets, consider pagination or caching.
  /// Corrupted rows are silently skipped to maintain stream stability.
  Stream<List<ui.Account>> watchAllAccounts() {
    return database.watchAllAccounts().asyncMap((rows) async {
      final accounts = <ui.Account>[];

      for (final row in rows) {
        try {
          final data = await encryptionService.decryptAccount(
            row.encryptedBlob,
            expectedId: row.id,
            expectedCreatedAtMillis: row.createdAt,
          );
          accounts.add(_toAccount(data));
        } catch (_) {
          // Skip corrupted rows in stream to maintain stability
          continue;
        }
      }

      return accounts;
    });
  }

  /// Check if any accounts exist in the database
  Future<bool> hasAccounts() async {
    return database.hasAccounts();
  }
}
