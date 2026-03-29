import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../exceptions/app_exception.dart';
import 'key_provider.dart';

/// Secure key provider that stores the encryption key in platform-specific
/// secure storage (Keychain on iOS, Keystore on Android).
class SecureKeyProvider implements KeyProvider {
  static const _storageKey = 'cachium_encryption_key';

  final FlutterSecureStorage _storage;
  Uint8List? _cachedKey;
  Future<Uint8List>? _pendingGetKey;

  SecureKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          mOptions: MacOsOptions(),
        );

  @override
  Future<Uint8List> getKey() async {
    if (_cachedKey != null) return _cachedKey!;

    // Prevent concurrent key generation — if another call is already
    // in progress, wait for it instead of racing to generate a second key.
    if (_pendingGetKey != null) return _pendingGetKey!;

    _pendingGetKey = _loadOrGenerateKey();
    try {
      return await _pendingGetKey!;
    } finally {
      _pendingGetKey = null;
    }
  }

  Future<Uint8List> _loadOrGenerateKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null) {
      final decoded = base64Decode(existing);
      if (decoded.length == 32) {
        _cachedKey = decoded;
        return decoded;
      }
      // Key exists but is corrupted — do NOT silently regenerate,
      // as that would make all encrypted data permanently unreadable.
      throw EncryptionKeyCorruptedException(
        message: 'Stored encryption key is corrupted '
            '(${decoded.length} bytes, expected 32). '
            'Encrypted data may be unrecoverable.',
      );
    }

    // Generate a new 32-byte key only on first use
    final key = Uint8List(32);
    final random = Random.secure();
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }

    // Store base64-encoded
    await _storage.write(key: _storageKey, value: base64Encode(key));

    // Re-read to confirm we won the race (another isolate may have written first)
    final confirmed = await _storage.read(key: _storageKey);
    if (confirmed != null) {
      final confirmedKey = base64Decode(confirmed);
      if (confirmedKey.length == 32) {
        _cachedKey = confirmedKey;
        return confirmedKey;
      }
    }

    _cachedKey = key;
    return key;
  }
}
