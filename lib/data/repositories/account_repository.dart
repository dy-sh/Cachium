import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../features/accounts/data/models/account.dart' as ui;
import '../models/account_data.dart';

/// Repository for managing encrypted account storage.
///
/// Converts between UI Account models and encrypted database records.
/// All sensitive data is encrypted before storage and decrypted on retrieval.
class AccountRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

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
      customColorValue: account.customColor?.value,
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
  Future<void> createAccount(ui.Account account) async {
    final data = _toData(account);
    final encryptedBlob = await encryptionService.encryptAccount(data);

    await database.insertAccount(
      id: account.id,
      createdAt: account.createdAt.millisecondsSinceEpoch,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Create or update an account (encrypt and upsert)
  Future<void> upsertAccount(ui.Account account) async {
    final data = _toData(account);
    final encryptedBlob = await encryptionService.encryptAccount(data);

    await database.upsertAccount(
      id: account.id,
      createdAt: account.createdAt.millisecondsSinceEpoch,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Get a single account by ID (fetch, decrypt, verify)
  Future<ui.Account?> getAccount(String id) async {
    final row = await database.getAccount(id);
    if (row == null) return null;

    final data = await encryptionService.decryptAccount(
      row.encryptedBlob,
      expectedId: row.id,
      expectedCreatedAtMillis: row.createdAt,
    );

    return _toAccount(data);
  }

  /// Get all non-deleted accounts
  Future<List<ui.Account>> getAllAccounts() async {
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
  }

  /// Update an existing account (re-encrypt and update)
  Future<void> updateAccount(ui.Account account) async {
    final data = _toData(account);
    final encryptedBlob = await encryptionService.encryptAccount(data);

    await database.updateAccount(
      id: account.id,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Soft delete an account (set isDeleted = true)
  Future<void> deleteAccount(String id) async {
    await database.softDeleteAccount(
      id,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Watch all accounts (for reactive UI)
  ///
  /// Note: Each emission triggers decryption of all rows.
  /// For large datasets, consider pagination or caching.
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
          // Skip corrupted rows in stream
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
