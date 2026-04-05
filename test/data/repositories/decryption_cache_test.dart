import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/data/repositories/decryption_cache.dart';

Uint8List _blob(List<int> bytes) => Uint8List.fromList(bytes);

void main() {
  group('DecryptionCache.get()', () {
    test('returns null for empty cache', () {
      final cache = DecryptionCache<String>();
      expect(cache.get('id-1', _blob([1, 2, 3])), isNull);
    });

    test('returns cached value when blob matches', () {
      final cache = DecryptionCache<String>();
      final blob = _blob([1, 2, 3, 4, 5]);
      cache.put('id-1', blob, 'value-1');
      expect(cache.get('id-1', blob), 'value-1');
    });

    test('returns null when blob changes (stale)', () {
      final cache = DecryptionCache<String>();
      cache.put('id-1', _blob([1, 2, 3]), 'value-1');
      expect(cache.get('id-1', _blob([4, 5, 6])), isNull);
    });

    test('returns null for wrong id', () {
      final cache = DecryptionCache<String>();
      final blob = _blob([1, 2, 3]);
      cache.put('id-1', blob, 'value-1');
      expect(cache.get('id-2', blob), isNull);
    });

    test('removes stale entry on miss', () {
      final cache = DecryptionCache<String>();
      final blob1 = _blob([1, 2, 3]);
      final blob2 = _blob([4, 5, 6]);
      cache.put('id-1', blob1, 'value-1');
      // First get with different blob removes the entry
      cache.get('id-1', blob2);
      // Now even the original blob returns null
      expect(cache.get('id-1', blob1), isNull);
    });
  });

  group('DecryptionCache.put()', () {
    test('overwrites existing entry', () {
      final cache = DecryptionCache<String>();
      final blob = _blob([1, 2, 3]);
      cache.put('id-1', blob, 'old');
      cache.put('id-1', blob, 'new');
      expect(cache.get('id-1', blob), 'new');
    });

    test('evicts oldest entry at capacity', () {
      final cache = DecryptionCache<String>(maxEntries: 2);
      final blob1 = _blob([1]);
      final blob2 = _blob([2]);
      final blob3 = _blob([3]);

      cache.put('id-1', blob1, 'value-1');
      cache.put('id-2', blob2, 'value-2');
      cache.put('id-3', blob3, 'value-3');

      // id-1 was evicted (oldest)
      expect(cache.get('id-1', blob1), isNull);
      expect(cache.get('id-2', blob2), 'value-2');
      expect(cache.get('id-3', blob3), 'value-3');
    });

    test('does not evict when updating existing key', () {
      final cache = DecryptionCache<String>(maxEntries: 2);
      final blob1 = _blob([1]);
      final blob2 = _blob([2]);

      cache.put('id-1', blob1, 'value-1');
      cache.put('id-2', blob2, 'value-2');
      // Update id-1, should not evict anything
      cache.put('id-1', blob1, 'updated');

      expect(cache.get('id-1', blob1), 'updated');
      expect(cache.get('id-2', blob2), 'value-2');
    });

    test('unlimited capacity when maxEntries is 0', () {
      final cache = DecryptionCache<String>(maxEntries: 0);
      for (int i = 0; i < 100; i++) {
        cache.put('id-$i', _blob([i]), 'value-$i');
      }
      // All entries should be present
      expect(cache.get('id-0', _blob([0])), 'value-0');
      expect(cache.get('id-99', _blob([99])), 'value-99');
    });
  });

  group('DecryptionCache.invalidate()', () {
    test('removes specific entry', () {
      final cache = DecryptionCache<String>();
      final blob = _blob([1, 2, 3]);
      cache.put('id-1', blob, 'value-1');
      cache.invalidate('id-1');
      expect(cache.get('id-1', blob), isNull);
    });

    test('no-op for non-existent id', () {
      final cache = DecryptionCache<String>();
      expect(() => cache.invalidate('nonexistent'), returnsNormally);
    });

    test('does not affect other entries', () {
      final cache = DecryptionCache<String>();
      final blob1 = _blob([1]);
      final blob2 = _blob([2]);
      cache.put('id-1', blob1, 'value-1');
      cache.put('id-2', blob2, 'value-2');
      cache.invalidate('id-1');
      expect(cache.get('id-2', blob2), 'value-2');
    });
  });

  group('DecryptionCache.clear()', () {
    test('removes all entries', () {
      final cache = DecryptionCache<String>();
      cache.put('id-1', _blob([1]), 'value-1');
      cache.put('id-2', _blob([2]), 'value-2');
      cache.clear();
      expect(cache.get('id-1', _blob([1])), isNull);
      expect(cache.get('id-2', _blob([2])), isNull);
    });
  });

  group('DecryptionCache fingerprint', () {
    test('empty blob is handled', () {
      final cache = DecryptionCache<String>();
      final emptyBlob = _blob([]);
      cache.put('id-1', emptyBlob, 'value');
      expect(cache.get('id-1', emptyBlob), 'value');
    });

    test('blobs with different lengths have different fingerprints', () {
      final cache = DecryptionCache<String>();
      cache.put('id-1', _blob([1, 2, 3]), 'value');
      expect(cache.get('id-1', _blob([1, 2, 3, 4])), isNull);
    });

    test('large blob uses head and tail for fingerprint', () {
      final cache = DecryptionCache<String>();
      // Blob larger than 32 bytes
      final blob = _blob(List.generate(64, (i) => i));
      cache.put('id-1', blob, 'value');
      expect(cache.get('id-1', blob), 'value');

      // Change a byte in the tail (last 16 bytes)
      final modified = Uint8List.fromList(blob);
      modified[63] = 255;
      expect(cache.get('id-1', modified), isNull);
    });

    test('large blob detects change in head region', () {
      final cache = DecryptionCache<String>();
      final blob = _blob(List.generate(64, (i) => i));
      cache.put('id-1', blob, 'value');

      // Change a byte in the head (first 32 bytes)
      final modified = Uint8List.fromList(blob);
      modified[0] = 255;
      expect(cache.get('id-1', modified), isNull);
    });
  });
}
