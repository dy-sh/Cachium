import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_database.dart';
import 'encryption_service.dart';
import 'key_provider.dart';

/// XOR mask for obfuscating legacy key bytes in the binary.
/// This prevents the key from appearing as a trivial sequential pattern
/// in decompiled output. TODO: Remove this code once migration adoption is ~100%.
const _xorMask = 0xA7;

/// The legacy mock key bytes used in Stage 1 development, XOR-obfuscated.
/// Original bytes were sequential [0x01..0x20]; stored here as (byte ^ 0xA7).
const _legacyMockKeyBytesObfuscated = [
  0xA6, 0xA5, 0xA4, 0xA3, 0xA2, 0xA1, 0xA0, 0xAF,
  0xAE, 0xAD, 0xAC, 0xAB, 0xAA, 0xA9, 0xA8, 0xB7,
  0xB6, 0xB5, 0xB4, 0xB3, 0xB2, 0xB1, 0xB0, 0xBF,
  0xBE, 0xBD, 0xBC, 0xBB, 0xBA, 0xB9, 0xB8, 0x87,
];

/// Result of a key migration operation.
class KeyMigrationResult {
  final bool wasNeeded;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const KeyMigrationResult({
    required this.wasNeeded,
    this.successCount = 0,
    this.failureCount = 0,
    this.errors = const [],
  });

  bool get hasFailures => failureCount > 0;

  static const notNeeded = KeyMigrationResult(wasNeeded: false);
}

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
  /// Returns a result with success/failure counts for visibility.
  Future<KeyMigrationResult> migrateIfNeeded(
    AppDatabase db,
    KeyProvider oldKeyProvider,
    KeyProvider newKeyProvider,
  ) async {
    final alreadyMigrated = await _storage.read(key: _migrationFlagKey);
    if (alreadyMigrated == 'true') return KeyMigrationResult.notNeeded;

    // Check if there's any data to migrate
    final hasData = await db.hasTransactions() ||
        await db.hasAccounts() ||
        await db.hasCategories() ||
        await db.hasAssets();

    if (!hasData) {
      // No data to migrate — mark as done so we don't check again
      await _storage.write(key: _migrationFlagKey, value: 'true');
      return KeyMigrationResult.notNeeded;
    }

    final oldService = EncryptionService(oldKeyProvider);
    final newService = EncryptionService(newKeyProvider);
    int totalSuccess = 0;
    int totalFailures = 0;
    final errors = <String>[];

    await db.transaction(() async {
      for (final tableName in [
        'transactions',
        'accounts',
        'categories',
        'budgets',
        'assets',
        'recurring_rules',
        'savings_goals',
        'transaction_templates',
      ]) {
        final result = await _migrateTable(
          db,
          tableName: tableName,
          oldService: oldService,
          newService: newService,
        );
        totalSuccess += result.success;
        totalFailures += result.failures;
        errors.addAll(result.errors);
      }
    });

    await _storage.write(key: _migrationFlagKey, value: 'true');

    return KeyMigrationResult(
      wasNeeded: true,
      successCount: totalSuccess,
      failureCount: totalFailures,
      errors: errors,
    );
  }

  /// Re-encrypt all rows in a table from old key to new key.
  Future<_TableMigrationResult> _migrateTable(
    AppDatabase db, {
    required String tableName,
    required EncryptionService oldService,
    required EncryptionService newService,
  }) async {
    final rows = await db.customSelect(
      'SELECT id, encrypted_blob FROM $tableName WHERE encrypted_blob IS NOT NULL',
    ).get();

    int success = 0;
    int failures = 0;
    final errors = <String>[];

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
        success++;
      } catch (e) {
        // If decryption fails (e.g., already migrated or corrupt),
        // skip this row but track the failure
        failures++;
        errors.add('$tableName/$id: $e');
      }
    }

    return _TableMigrationResult(
      success: success,
      failures: failures,
      errors: errors,
    );
  }
}

class _TableMigrationResult {
  final int success;
  final int failures;
  final List<String> errors;

  const _TableMigrationResult({
    required this.success,
    required this.failures,
    required this.errors,
  });
}

/// Legacy key provider for migration purposes only.
/// Uses the obfuscated mock key from Stage 1.
class LegacyKeyProvider implements KeyProvider {
  @override
  Future<Uint8List> getKey() async {
    return Uint8List.fromList(
      _legacyMockKeyBytesObfuscated.map((b) => b ^ _xorMask).toList(),
    );
  }
}
