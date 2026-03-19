import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Hashes and verifies PIN codes and passwords using SHA-256.
///
/// Stored format: `sha256:<base64-encoded-hash>`
/// This prefix allows detection of legacy plaintext credentials
/// for transparent migration.
class CredentialHasher {
  static final _sha256 = Sha256();

  /// Prefix used to identify hashed credentials.
  static const _prefix = 'sha256:';

  /// Hash a credential (PIN or password).
  static Future<String> hash(String credential) async {
    final saltedInput = utf8.encode('cachium_app_lock_$credential');
    final digest = await _sha256.hash(saltedInput);
    return '$_prefix${base64Encode(digest.bytes)}';
  }

  /// Verify a credential against a stored hash.
  ///
  /// Also handles legacy plaintext credentials for migration:
  /// if [storedValue] is not hashed, falls back to direct comparison.
  static Future<bool> verify(String credential, String storedValue) async {
    if (storedValue.startsWith(_prefix)) {
      final candidateHash = await hash(credential);
      return candidateHash == storedValue;
    }
    // Legacy plaintext fallback
    return credential == storedValue;
  }

  /// Returns true if the value is already hashed.
  static bool isHashed(String value) => value.startsWith(_prefix);
}
