import 'dart:typed_data';

/// Abstract class for providing encryption keys.
///
/// In Stage 1, we use [MockKeyProvider] with a hardcoded key.
/// In Stage 2, this will be replaced with [SecureKeyProvider] that
/// stores keys in flutter_secure_storage or platform-specific secure storage.
abstract class KeyProvider {
  /// Returns the 32-byte AES-256 encryption key.
  ///
  /// Throws an exception if the key cannot be retrieved.
  Future<Uint8List> getKey();
}

/// Mock key provider for Stage 1 development.
///
/// WARNING: This uses a hardcoded key and is NOT secure for production.
/// This should only be used during development and will be replaced
/// with [SecureKeyProvider] in Stage 2.
class MockKeyProvider implements KeyProvider {
  // Hardcoded 32-byte key for development (AES-256 requires 32 bytes)
  // In Stage 2, this will be replaced with secure key storage
  static final Uint8List _mockKey = Uint8List.fromList([
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
    0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
    0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20,
  ]);

  @override
  Future<Uint8List> getKey() async {
    // Simulating async operation for future compatibility
    return _mockKey;
  }
}
