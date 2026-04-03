import 'dart:convert';
import 'dart:typed_data';

import 'package:cachium/core/database/services/key_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_key_provider.dart';

void main() {
  late TestKeyProvider keyProvider;
  late KeyBackupService service;

  setUp(() {
    keyProvider = TestKeyProvider();
    service = KeyBackupService(keyProvider);
  });

  group('exportKeyAsBase64', () {
    test('returns a valid base64 string', () async {
      final result = await service.exportKeyAsBase64();
      final decoded = base64Decode(result);
      expect(decoded.length, 32);
    });

    test('returns same key on repeated calls', () async {
      final first = await service.exportKeyAsBase64();
      final second = await service.exportKeyAsBase64();
      expect(first, second);
    });
  });

  group('isValidKeyBackup', () {
    test('returns true for valid 32-byte base64', () {
      final key = base64Encode(Uint8List(32));
      expect(service.isValidKeyBackup(key), true);
    });

    test('returns false for too-short key', () {
      final key = base64Encode(Uint8List(16));
      expect(service.isValidKeyBackup(key), false);
    });

    test('returns false for too-long key', () {
      final key = base64Encode(Uint8List(64));
      expect(service.isValidKeyBackup(key), false);
    });

    test('returns false for invalid base64', () {
      expect(service.isValidKeyBackup('not-valid-base64!!!'), false);
    });

    test('returns false for empty string', () {
      expect(service.isValidKeyBackup(''), false);
    });

    test('trims whitespace', () {
      final key = base64Encode(Uint8List(32));
      expect(service.isValidKeyBackup('  $key  '), true);
    });
  });

  group('verifyBackupMatchesCurrent', () {
    test('returns true for matching key', () async {
      final exported = await service.exportKeyAsBase64();
      expect(await service.verifyBackupMatchesCurrent(exported), true);
    });

    test('returns false for different key', () async {
      final differentKey = base64Encode(Uint8List.fromList(
        List.generate(32, (i) => 255 - i),
      ));
      expect(await service.verifyBackupMatchesCurrent(differentKey), false);
    });

    test('returns false for invalid base64', () async {
      expect(await service.verifyBackupMatchesCurrent('invalid'), false);
    });

    test('returns false for wrong-length key', () async {
      final shortKey = base64Encode(Uint8List(16));
      expect(await service.verifyBackupMatchesCurrent(shortKey), false);
    });
  });

  group('restoreFromBase64', () {
    test('restores a valid key', () async {
      final newKey = Uint8List.fromList(List.generate(32, (i) => 255 - i));
      final newKeyB64 = base64Encode(newKey);

      await service.restoreFromBase64(newKeyB64);

      final currentKey = await keyProvider.getKey();
      expect(currentKey, newKey);
    });

    test('exported key matches after restore', () async {
      final newKey = Uint8List.fromList(List.generate(32, (i) => 255 - i));
      final newKeyB64 = base64Encode(newKey);

      await service.restoreFromBase64(newKeyB64);

      final exported = await service.exportKeyAsBase64();
      expect(exported, newKeyB64);
    });

    test('throws for invalid-length key', () async {
      final shortKey = base64Encode(Uint8List(16));
      expect(
        () => service.restoreFromBase64(shortKey),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
