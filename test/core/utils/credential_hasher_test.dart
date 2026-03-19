import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/utils/credential_hasher.dart';

void main() {
  group('CredentialHasher', () {
    test('hash produces consistent output for same input', () async {
      final hash1 = await CredentialHasher.hash('1234');
      final hash2 = await CredentialHasher.hash('1234');
      expect(hash1, equals(hash2));
    });

    test('hash produces different output for different input', () async {
      final hash1 = await CredentialHasher.hash('1234');
      final hash2 = await CredentialHasher.hash('5678');
      expect(hash1, isNot(equals(hash2)));
    });

    test('hash output starts with prefix', () async {
      final hash = await CredentialHasher.hash('1234');
      expect(hash.startsWith('sha256:'), isTrue);
    });

    test('verify returns true for correct credential', () async {
      final hash = await CredentialHasher.hash('mypin');
      final result = await CredentialHasher.verify('mypin', hash);
      expect(result, isTrue);
    });

    test('verify returns false for incorrect credential', () async {
      final hash = await CredentialHasher.hash('mypin');
      final result = await CredentialHasher.verify('wrongpin', hash);
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

    test('isHashed detects hashed values', () async {
      final hash = await CredentialHasher.hash('test');
      expect(CredentialHasher.isHashed(hash), isTrue);
    });

    test('isHashed returns false for plaintext', () {
      expect(CredentialHasher.isHashed('1234'), isFalse);
      expect(CredentialHasher.isHashed('mypassword'), isFalse);
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
  });
}
