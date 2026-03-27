import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_provider.dart';

/// Secure key provider that stores the encryption key in platform-specific
/// secure storage (Keychain on iOS, Keystore on Android).
class SecureKeyProvider implements KeyProvider {
  static const _storageKey = 'cachium_encryption_key';

  final FlutterSecureStorage _storage;

  SecureKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<Uint8List> getKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null) {
      final decoded = base64Decode(existing);
      if (decoded.length == 32) return decoded;
      // Key is corrupted — fall through to generate a new one
    }

    // Generate a new 32-byte key using secure random
    final key = Uint8List(32);
    final random = Random.secure();
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }

    // Store base64-encoded
    await _storage.write(key: _storageKey, value: base64Encode(key));
    return key;
  }
}
