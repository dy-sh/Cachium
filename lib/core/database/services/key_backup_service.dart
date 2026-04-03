import 'dart:convert';
import 'dart:typed_data';

import 'key_provider.dart';

/// Service for backing up and restoring the encryption key.
///
/// Users can export their key as a base64 string and later restore it
/// if they lose access to their device's secure storage.
class KeyBackupService {
  final KeyProvider _keyProvider;

  KeyBackupService(this._keyProvider);

  /// Exports the current encryption key as a base64 string.
  Future<String> exportKeyAsBase64() async {
    final key = await _keyProvider.getKey();
    return base64Encode(key);
  }

  /// Validates that a base64 string is a valid 32-byte key backup.
  bool isValidKeyBackup(String b64) {
    try {
      final decoded = base64Decode(b64.trim());
      return decoded.length == 32;
    } catch (_) {
      return false;
    }
  }

  /// Checks if the given backup matches the currently active key.
  Future<bool> verifyBackupMatchesCurrent(String b64) async {
    try {
      final decoded = base64Decode(b64.trim());
      if (decoded.length != 32) return false;
      final current = await _keyProvider.getKey();
      if (decoded.length != current.length) return false;
      for (int i = 0; i < decoded.length; i++) {
        if (decoded[i] != current[i]) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Restores the encryption key from a base64 backup.
  /// Throws if the key is invalid (not 32 bytes).
  Future<void> restoreFromBase64(String b64) async {
    final decoded = Uint8List.fromList(base64Decode(b64.trim()));
    if (decoded.length != 32) {
      throw ArgumentError('Invalid key: expected 32 bytes, got ${decoded.length}');
    }
    await _keyProvider.restoreKey(decoded);
  }
}
