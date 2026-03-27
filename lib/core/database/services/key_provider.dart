import 'dart:typed_data';

/// Abstract class for providing encryption keys.
///
/// Use [SecureKeyProvider] for production, which stores keys in
/// platform-specific secure storage (Keychain on iOS, Keystore on Android).
abstract class KeyProvider {
  /// Returns the 32-byte AES-256 encryption key.
  ///
  /// Throws an exception if the key cannot be retrieved.
  Future<Uint8List> getKey();
}
