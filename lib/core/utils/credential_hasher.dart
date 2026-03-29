import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Hashes and verifies PIN codes and passwords using PBKDF2.
///
/// Stored formats:
/// - `pbkdf2:<iterations>:<base64-salt>:<base64-hash>` (current)
/// - `sha256:<base64-encoded-hash>` (legacy v2, auto-migrated)
/// - plaintext (legacy v1, auto-migrated)
class CredentialHasher {
  static final _sha256 = Sha256();
  static const _pbkdf2Prefix = 'pbkdf2:';
  static const _sha256Prefix = 'sha256:';
  static const _iterations = 100000;
  static const _hashLength = 32; // 256 bits
  static const _saltLength = 16; // 128 bits

  /// Hash a credential (PIN or password) using PBKDF2.
  static Future<String> hash(String credential) async {
    final salt = _generateSalt();
    final hashBytes = await _pbkdf2Hash(credential, salt);
    return '$_pbkdf2Prefix$_iterations:${base64Encode(salt)}:${base64Encode(hashBytes)}';
  }

  /// Verify a credential against a stored hash.
  ///
  /// Handles all stored formats:
  /// - `pbkdf2:` — current PBKDF2 format
  /// - `sha256:` — legacy SHA-256 format
  /// - plaintext — legacy direct comparison
  static Future<bool> verify(String credential, String storedValue) async {
    if (storedValue.startsWith(_pbkdf2Prefix)) {
      return _verifyPbkdf2(credential, storedValue);
    }
    if (storedValue.startsWith(_sha256Prefix)) {
      return _verifySha256(credential, storedValue);
    }
    // Legacy plaintext fallback
    return credential == storedValue;
  }

  /// Returns true if the value is hashed (either PBKDF2 or SHA-256).
  static bool isHashed(String value) =>
      value.startsWith(_pbkdf2Prefix) || value.startsWith(_sha256Prefix);

  /// Returns true if the value uses the current PBKDF2 format.
  static bool isPbkdf2(String value) => value.startsWith(_pbkdf2Prefix);

  /// Returns true if the stored value should be upgraded to PBKDF2.
  /// True for legacy SHA-256 and plaintext formats.
  static bool needsUpgrade(String storedValue) => !isPbkdf2(storedValue);

  static List<int> _generateSalt() {
    final random = Random.secure();
    return List<int>.generate(_saltLength, (_) => random.nextInt(256));
  }

  static Future<List<int>> _pbkdf2Hash(String credential, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: _hashLength * 8,
    );
    final secretKey = SecretKey(utf8.encode(credential));
    final derived = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    return await derived.extractBytes();
  }

  static Future<bool> _verifyPbkdf2(String credential, String storedValue) async {
    final parts = storedValue.substring(_pbkdf2Prefix.length).split(':');
    if (parts.length != 3) return false;

    final iterations = int.tryParse(parts[0]);
    if (iterations == null) return false;

    final List<int> salt;
    final List<int> expectedHash;
    try {
      salt = base64Decode(parts[1]);
      expectedHash = base64Decode(parts[2]);
    } catch (_) {
      // Corrupted base64 in stored hash — reject rather than crash
      return false;
    }

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: expectedHash.length * 8,
    );
    final secretKey = SecretKey(utf8.encode(credential));
    final derived = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    final candidateHash = await derived.extractBytes();

    // Constant-time comparison (no early return on length mismatch)
    var result = candidateHash.length ^ expectedHash.length;
    final maxLen = candidateHash.length > expectedHash.length
        ? candidateHash.length
        : expectedHash.length;
    for (var i = 0; i < maxLen; i++) {
      final a = i < candidateHash.length ? candidateHash[i] : 0;
      final b = i < expectedHash.length ? expectedHash[i] : 0;
      result |= a ^ b;
    }
    return result == 0;
  }

  static Future<bool> _verifySha256(String credential, String storedValue) async {
    final saltedInput = utf8.encode('cachium_app_lock_$credential');
    final digest = await _sha256.hash(saltedInput);
    final candidateHash = '$_sha256Prefix${base64Encode(digest.bytes)}';
    // Constant-time comparison (no early return on length mismatch)
    var result = candidateHash.length ^ storedValue.length;
    final maxLen = candidateHash.length > storedValue.length
        ? candidateHash.length
        : storedValue.length;
    for (var i = 0; i < maxLen; i++) {
      final a = i < candidateHash.length ? candidateHash.codeUnitAt(i) : 0;
      final b = i < storedValue.length ? storedValue.codeUnitAt(i) : 0;
      result |= a ^ b;
    }
    return result == 0;
  }
}
