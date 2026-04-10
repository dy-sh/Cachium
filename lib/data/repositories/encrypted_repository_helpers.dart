import 'dart:typed_data';

import '../../core/utils/app_logger.dart';
import '../../core/utils/decrypt_batch.dart';
import 'decryption_cache.dart';

/// Decrypts a batch of encrypted rows through [DecryptionCache], tracks
/// corrupted rows, and returns only the successfully decrypted entities.
///
/// This captures the identical getAll/watch pattern used by every encrypted
/// repository (`AccountRepository`, `BudgetRepository`, `TransactionRepository`,
/// …). Each repo passes its own extractor and decrypt functions and gets back
/// a corruption-aware result.
///
/// - [decryptRow] receives the row directly so the caller can inline
///   entity-specific `expected*` parameters (e.g. `expectedCreatedAtMillis`
///   for most entities, `expectedSortOrder` for categories).
///
/// Returns a record with:
/// - [entities]: successfully decrypted and mapped entities
/// - [corruptedCount]: how many rows failed to decrypt (pass to
///   `updateCorruptedCount()` from the CorruptionTracker mixin)
Future<({List<TEntity> entities, int corruptedCount})>
    decryptRowsWithCache<TEntity, TData, TRow>({
  required List<TRow> rows,
  required String Function(TRow row) rowId,
  required Uint8List Function(TRow row) rowBlob,
  required Future<TData> Function(TRow row) decryptRow,
  required TEntity Function(TData data) toEntity,
  required DecryptionCache<TEntity> cache,
  required AppLogger log,
  required String entityType,
}) async {
  int corruptedCount = 0;

  final results = await decryptBatch(
    rows.map((row) => () async {
      final id = rowId(row);
      final blob = rowBlob(row);
      try {
        final cached = cache.get(id, blob);
        if (cached != null) return cached;
        final data = await decryptRow(row);
        final result = toEntity(data);
        cache.put(id, blob, result);
        return result;
      } catch (e) {
        log.warning('Corrupted $entityType row id=$id: $e');
        corruptedCount++;
        return null;
      }
    }),
  );

  return (
    entities: results.whereType<TEntity>().toList(),
    corruptedCount: corruptedCount,
  );
}
