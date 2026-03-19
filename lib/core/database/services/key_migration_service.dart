import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_database.dart';
import 'encryption_service.dart';
import 'key_provider.dart';

/// The hardcoded mock key bytes used in Stage 1 development.
/// Kept here only for migration purposes.
const _legacyMockKeyBytes = [
  0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
  0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
  0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20,
];

/// Service for migrating encrypted data from the legacy mock key
/// to the new secure key stored in flutter_secure_storage.
class KeyMigrationService {
  static const _migrationFlagKey = 'cachium_key_migrated';

  final FlutterSecureStorage _storage;

  KeyMigrationService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  /// Check if migration is needed and perform it if so.
  ///
  /// Decrypts all encrypted rows with the old key and re-encrypts them
  /// with the new key, all within a database transaction.
  Future<void> migrateIfNeeded(
    AppDatabase db,
    KeyProvider oldKeyProvider,
    KeyProvider newKeyProvider,
  ) async {
    final alreadyMigrated = await _storage.read(key: _migrationFlagKey);
    if (alreadyMigrated == 'true') return;

    // Check if there's any data to migrate
    final hasData = await db.hasTransactions() ||
        await db.hasAccounts() ||
        await db.hasCategories() ||
        await db.hasAssets();

    if (!hasData) {
      // No data to migrate — mark as done so we don't check again
      await _storage.write(key: _migrationFlagKey, value: 'true');
      return;
    }

    final oldService = EncryptionService(oldKeyProvider);
    final newService = EncryptionService(newKeyProvider);

    await db.transaction(() async {
      await _migrateTable(
        db,
        tableName: 'transactions',
        oldService: oldService,
        newService: newService,
      );
      await _migrateTable(
        db,
        tableName: 'accounts',
        oldService: oldService,
        newService: newService,
      );
      await _migrateTable(
        db,
        tableName: 'categories',
        oldService: oldService,
        newService: newService,
      );
      await _migrateTable(
        db,
        tableName: 'budgets',
        oldService: oldService,
        newService: newService,
      );
      await _migrateTable(
        db,
        tableName: 'assets',
        oldService: oldService,
        newService: newService,
      );
      await _migrateTable(
        db,
        tableName: 'recurring_rules',
        oldService: oldService,
        newService: newService,
      );
      await _migrateTable(
        db,
        tableName: 'savings_goals',
        oldService: oldService,
        newService: newService,
      );
      await _migrateTable(
        db,
        tableName: 'transaction_templates',
        oldService: oldService,
        newService: newService,
      );
    });

    await _storage.write(key: _migrationFlagKey, value: 'true');
  }

  /// Re-encrypt all rows in a table from old key to new key.
  Future<void> _migrateTable(
    AppDatabase db, {
    required String tableName,
    required EncryptionService oldService,
    required EncryptionService newService,
  }) async {
    final rows = await db.customSelect(
      'SELECT id, encrypted_blob FROM $tableName WHERE encrypted_blob IS NOT NULL',
    ).get();

    for (final row in rows) {
      final id = row.read<String>('id');
      final blob = row.read<Uint8List>('encrypted_blob');

      try {
        // Decrypt with old key
        final json = await oldService.decryptJson(blob);
        // Re-encrypt with new key
        final newBlob = await newService.encryptJson(json);

        await db.customUpdate(
          'UPDATE $tableName SET encrypted_blob = ? WHERE id = ?',
          variables: [Variable.withBlob(newBlob), Variable.withString(id)],
          updates: {},
        );
      } catch (_) {
        // If decryption fails (e.g., already migrated or corrupt),
        // skip this row silently
      }
    }
  }
}

/// Legacy key provider for migration purposes only.
/// Uses the hardcoded mock key from Stage 1.
class LegacyKeyProvider implements KeyProvider {
  @override
  Future<Uint8List> getKey() async {
    return Uint8List.fromList(_legacyMockKeyBytes);
  }
}
