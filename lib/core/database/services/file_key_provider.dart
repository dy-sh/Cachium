import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../exceptions/app_exception.dart';
import 'key_provider.dart';

/// File-based key provider for desktop platforms where Keychain/Keystore
/// may not be available (e.g. macOS debug builds without code signing).
///
/// Stores the encryption key in a file within the app's support directory.
/// The directory is sandboxed on macOS, so this is acceptable for development.
/// The key is cached in memory after the first load to avoid repeated
/// platform channel calls (which fail on background isolates).
class FileKeyProvider implements KeyProvider {
  static const _fileName = 'cachium_key.dat';

  Uint8List? _cachedKey;

  @override
  Future<Uint8List> getKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_fileName');

    if (file.existsSync()) {
      final content = file.readAsStringSync();
      final decoded = base64Decode(content.trim());
      if (decoded.length == 32) {
        _cachedKey = decoded;
        return decoded;
      }
      throw EncryptionKeyCorruptedException(
        message: 'Stored encryption key is corrupted '
            '(${decoded.length} bytes, expected 32).',
      );
    }

    // Generate a new 32-byte key
    final key = Uint8List(32);
    final random = Random.secure();
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }

    file.writeAsStringSync(base64Encode(key));
    _cachedKey = key;
    return key;
  }
}
