import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/tags/data/models/tag.dart' as ui;
import '../encryption/tag_data.dart';
import 'corruption_tracker.dart';
import 'decryption_cache.dart';

/// Repository for managing encrypted tag storage.
class TagRepository with CorruptionTracker {
  final db.AppDatabase database;
  final EncryptionService encryptionService;
  final _decryptionCache = DecryptionCache<ui.Tag>();

  static const _entityType = 'Tag';

  TagRepository({
    required this.database,
    required this.encryptionService,
  });

  TagData _toData(ui.Tag tag) {
    return TagData(
      id: tag.id,
      name: tag.name,
      colorIndex: tag.colorIndex,
      iconCodePoint: tag.icon.codePoint,
      iconFontFamily: tag.icon.fontFamily ?? 'lucide',
      iconFontPackage: tag.icon.fontPackage,
      sortOrder: tag.sortOrder,
    );
  }

  ui.Tag _toTag(TagData data) {
    return ui.Tag(
      id: data.id,
      name: data.name,
      colorIndex: data.colorIndex,
      icon: IconData(
        data.iconCodePoint,
        fontFamily: data.iconFontFamily,
        fontPackage: data.iconFontPackage,
      ),
      sortOrder: data.sortOrder,
    );
  }

  Future<void> createTag(ui.Tag tag) async {
    try {
      final data = _toData(tag);
      final encryptedBlob = await encryptionService.encryptTag(data);

      await database.insertTag(
        id: tag.id,
        sortOrder: tag.sortOrder,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(tag.id);
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<void> upsertTag(ui.Tag tag) async {
    try {
      final data = _toData(tag);
      final encryptedBlob = await encryptionService.encryptTag(data);

      await database.upsertTag(
        id: tag.id,
        sortOrder: tag.sortOrder,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(tag.id);
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<ui.Tag?> getTag(String id) async {
    final row = await database.getTag(id);
    if (row == null) return null;

    try {
      final cached = _decryptionCache.get(row.id, row.encryptedBlob);
      if (cached != null) return cached;
      final data = await encryptionService.decryptTag(
        row.encryptedBlob,
        expectedId: row.id,
        expectedSortOrder: row.sortOrder,
      );
      final result = _toTag(data);
      _decryptionCache.put(row.id, row.encryptedBlob, result);
      return result;
    } catch (e) {
      throw RepositoryException.decryption(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  Future<List<ui.Tag>> getAllTags() async {
    try {
      final rows = await database.getAllTags();
      int corruptedCount = 0;

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final cached = _decryptionCache.get(row.id, row.encryptedBlob);
            if (cached != null) return cached;
            final data = await encryptionService.decryptTag(
              row.encryptedBlob,
              expectedId: row.id,
              expectedSortOrder: row.sortOrder,
            );
            final result = _toTag(data);
            _decryptionCache.put(row.id, row.encryptedBlob, result);
            return result;
          } catch (e) {
            debugPrint('WARNING: Corrupted tag row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      updateCorruptedCount(corruptedCount);
      return results.whereType<ui.Tag>().toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  Future<void> updateTag(ui.Tag tag) async {
    try {
      final data = _toData(tag);
      final encryptedBlob = await encryptionService.encryptTag(data);

      await database.updateTag(
        id: tag.id,
        sortOrder: tag.sortOrder,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(tag.id);
    } catch (e) {
      throw RepositoryException.update(
        entityType: _entityType,
        entityId: tag.id,
        cause: e,
      );
    }
  }

  Future<void> deleteTag(String id) async {
    try {
      await database.softDeleteTag(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
      // Also remove all junction entries for this tag
      await database.removeAllTagsForTag(id);
      _decryptionCache.invalidate(id);
    } catch (e) {
      throw RepositoryException.delete(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  Stream<List<ui.Tag>> watchAllTags() {
    return database.watchAllTags().asyncMap((rows) async {
      int corruptedCount = 0;

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final cached = _decryptionCache.get(row.id, row.encryptedBlob);
            if (cached != null) return cached;
            final data = await encryptionService.decryptTag(
              row.encryptedBlob,
              expectedId: row.id,
              expectedSortOrder: row.sortOrder,
            );
            final result = _toTag(data);
            _decryptionCache.put(row.id, row.encryptedBlob, result);
            return result;
          } catch (e) {
            debugPrint('WARNING: Corrupted tag row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      updateCorruptedCount(corruptedCount);
      return results.whereType<ui.Tag>().toList();
    });
  }

  // Junction table operations

  Future<List<String>> getTagIdsForTransaction(String transactionId) async {
    return database.getTagIdsForTransaction(transactionId);
  }

  Future<void> setTagsForTransaction(
    String transactionId,
    List<String> tagIds,
  ) async {
    await database.setTagsForTransaction(transactionId, tagIds);
  }

  Future<List<String>> getTransactionIdsForTag(String tagId) async {
    return database.getTransactionIdsForTag(tagId);
  }

  Future<void> removeTagsForTransaction(String transactionId) async {
    await database.removeAllTagsForTransaction(transactionId);
  }
}
