import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/utils/credential_hasher.dart';

void main() {
  group('CredentialHasher', () {
    test('hash produces PBKDF2 format output', () async {
      final hash = await CredentialHasher.hash('1234');
      expect(hash.startsWith('pbkdf2:'), isTrue);
      // Format: pbkdf2:<iterations>:<base64-salt>:<base64-hash>
      final parts = hash.substring(7).split(':');
      expect(parts.length, 3);
      expect(int.tryParse(parts[0]), isNotNull);
    });

    test('hash produces different output each time (random salt)', () async {
      final hash1 = await CredentialHasher.hash('1234');
      final hash2 = await CredentialHasher.hash('1234');
      // Different salts mean different outputs
      expect(hash1, isNot(equals(hash2)));
    });

    test('verify returns true for correct credential (PBKDF2)', () async {
      final hash = await CredentialHasher.hash('mypin');
      final result = await CredentialHasher.verify('mypin', hash);
      expect(result, isTrue);
    });

    test('verify returns false for incorrect credential (PBKDF2)', () async {
      final hash = await CredentialHasher.hash('mypin');
      final result = await CredentialHasher.verify('wrongpin', hash);
      expect(result, isFalse);
    });

    test('verify handles legacy SHA-256 credentials', () async {
      // Simulate a legacy sha256 hash (the old format)
      // We can't easily produce one without the old code, but we can test
      // by constructing the expected format
      const credential = 'testpin';
      // The old hash function used: sha256(utf8.encode('cachium_app_lock_$credential'))
      // For backward compat, verify should still work with sha256: prefix
      // We test by checking the verify path handles sha256: prefix
      final sha256Hash = 'sha256:dGVzdA=='; // fake, won't match
      final result = await CredentialHasher.verify(credential, sha256Hash);
      // Won't match because the hash is fake, but it shouldn't throw
      expect(result, isFalse);
    });

    test('verify handles legacy plaintext credentials', () async {
      // Legacy plaintext - should match directly
      final result = await CredentialHasher.verify('1234', '1234');
      expect(result, isTrue);
    });

    test('verify rejects wrong legacy plaintext credentials', () async {
      final result = await CredentialHasher.verify('5678', '1234');
      expect(result, isFalse);
    });

    test('isHashed detects PBKDF2 values', () async {
      final hash = await CredentialHasher.hash('test');
      expect(CredentialHasher.isHashed(hash), isTrue);
    });

    test('isHashed detects SHA-256 values', () {
      expect(CredentialHasher.isHashed('sha256:abc123'), isTrue);
    });

    test('isHashed returns false for plaintext', () {
      expect(CredentialHasher.isHashed('1234'), isFalse);
      expect(CredentialHasher.isHashed('mypassword'), isFalse);
    });

    test('isPbkdf2 distinguishes PBKDF2 from SHA-256', () async {
      final hash = await CredentialHasher.hash('test');
      expect(CredentialHasher.isPbkdf2(hash), isTrue);
      expect(CredentialHasher.isPbkdf2('sha256:abc123'), isFalse);
      expect(CredentialHasher.isPbkdf2('plaintext'), isFalse);
    });

    test('hash works for PIN codes of various lengths', () async {
      for (final pin in ['1234', '12345', '123456', '1234567', '12345678']) {
        final hash = await CredentialHasher.hash(pin);
        final verified = await CredentialHasher.verify(pin, hash);
        expect(verified, isTrue, reason: 'Failed for PIN length ${pin.length}');
      }
    });

    test('hash works for passwords with special characters', () async {
      final password = r'p@$$w0rd!#%^&*';
      final hash = await CredentialHasher.hash(password);
      final verified = await CredentialHasher.verify(password, hash);
      expect(verified, isTrue);
    });

    test('hash works for empty string', () async {
      final hash = await CredentialHasher.hash('');
      final verified = await CredentialHasher.verify('', hash);
      expect(verified, isTrue);
    });

    test('verify rejects malformed PBKDF2 strings', () async {
      // Missing parts
      final result1 = await CredentialHasher.verify('test', 'pbkdf2:invalid');
      expect(result1, isFalse);

      // Non-numeric iterations
      final result2 = await CredentialHasher.verify('test', 'pbkdf2:abc:c2FsdA==:aGFzaA==');
      expect(result2, isFalse);
    });
  });
}
