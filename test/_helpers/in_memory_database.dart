import 'dart:typed_data';

import 'package:cachium/core/database/app_database.dart';
import 'package:cachium/core/database/services/encryption_service.dart';
import 'package:cachium/core/database/services/key_provider.dart';
import 'package:drift/native.dart';

/// Builds a fresh in-memory [AppDatabase] for tests using drift's NativeDatabase.
///
/// The caller owns the returned database and must call `close()` in teardown.
AppDatabase buildInMemoryDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

/// Deterministic key provider for tests — returns a fixed 32-byte key.
///
/// Using a constant key makes encrypted round-trip tests reproducible.
class FixedTestKeyProvider extends KeyProvider {
  Uint8List _key;

  FixedTestKeyProvider()
      : _key = Uint8List.fromList(List.generate(32, (i) => i));

  @override
  Future<Uint8List> getKey() async => _key;

  @override
  Future<void> restoreKey(Uint8List key) async => _key = key;
}

/// Convenience: build an [EncryptionService] wired to a fresh [FixedTestKeyProvider].
EncryptionService buildTestEncryptionService() =>
    EncryptionService(FixedTestKeyProvider());
