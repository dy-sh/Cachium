import 'dart:typed_data';

/// In-memory cache for decrypted entity data, keyed by entity ID and
/// a fingerprint of the encrypted blob.
///
/// Avoids redundant AES-GCM decryptions when a database stream emits
/// rows that haven't actually changed.
class DecryptionCache<T> {
  final int _maxEntries;
  final Map<String, _CacheEntry<T>> _cache = {};

  /// Creates a cache with an optional maximum size.
  /// When [maxEntries] is 0, there is no size limit.
  DecryptionCache({int maxEntries = 0}) : _maxEntries = maxEntries;

  /// Returns the cached value for [id] if the blob fingerprint matches,
  /// or null if not cached / stale.
  T? get(String id, Uint8List encryptedBlob) {
    final entry = _cache[id];
    if (entry == null) return null;
    if (entry.blobFingerprint == _fingerprint(encryptedBlob)) {
      return entry.value;
    }
    // Blob changed — cache is stale for this entry
    _cache.remove(id);
    return null;
  }

  /// Stores a decrypted value associated with [id] and [encryptedBlob].
  void put(String id, Uint8List encryptedBlob, T value) {
    // Evict oldest entry if at capacity
    if (_maxEntries > 0 && _cache.length >= _maxEntries && !_cache.containsKey(id)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[id] = _CacheEntry(
      blobFingerprint: _fingerprint(encryptedBlob),
      value: value,
    );
  }

  /// Remove a specific entry (call on update/delete).
  void invalidate(String id) => _cache.remove(id);

  /// Clear all cached entries.
  void clear() => _cache.clear();

  /// Fingerprint: length + first 32 bytes (covers the AES-GCM nonce/IV)
  /// + last 16 bytes (covers the auth tag). Since AES-GCM uses a random
  /// nonce per encryption, any change to the plaintext or re-encryption
  /// produces a different blob. Using more bytes reduces collision risk.
  int _fingerprint(Uint8List blob) {
    if (blob.isEmpty) return 0;
    int hash = blob.length;
    // Hash the first 32 bytes (nonce + early ciphertext)
    final headEnd = blob.length < 32 ? blob.length : 32;
    for (int i = 0; i < headEnd; i++) {
      hash = hash * 31 + blob[i];
    }
    // Hash the last 16 bytes (auth tag region)
    if (blob.length > 32) {
      final tailStart = blob.length - 16;
      for (int i = tailStart; i < blob.length; i++) {
        hash = hash * 31 + blob[i];
      }
    }
    return hash;
  }
}

class _CacheEntry<T> {
  final int blobFingerprint;
  final T value;

  _CacheEntry({required this.blobFingerprint, required this.value});
}
