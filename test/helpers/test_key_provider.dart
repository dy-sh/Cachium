import 'dart:typed_data';
import 'package:cachium/core/database/services/key_provider.dart';

/// Test key provider with a fixed 32-byte key for testing.
class TestKeyProvider extends KeyProvider {
  Uint8List _key;

  TestKeyProvider()
      : _key = Uint8List.fromList(List.generate(32, (i) => i));

  TestKeyProvider.fromKey(this._key);

  @override
  Future<Uint8List> getKey() async => _key;

  @override
  Future<void> restoreKey(Uint8List key) async => _key = key;
}
