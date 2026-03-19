import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/tags/data/models/tag.dart' as ui;
import '../encryption/tag_data.dart';

/// Repository for managing encrypted tag storage.
class TagRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'Tag';

  int _lastCorruptedCount = 0;
  int get lastCorruptedCount => _lastCorruptedCount;

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
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<ui.Tag?> getTag(String id) async {
    final row = await database.getTag(id);
    if (row == null) return null;

    try {
      final data = await encryptionService.decryptTag(
        row.encryptedBlob,
        expectedId: row.id,
        expectedSortOrder: row.sortOrder,
      );
      return _toTag(data);
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
      final tags = <ui.Tag>[];

      for (final row in rows) {
        final data = await encryptionService.decryptTag(
          row.encryptedBlob,
          expectedId: row.id,
          expectedSortOrder: row.sortOrder,
        );
        tags.add(_toTag(data));
      }

      return tags;
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
      final tags = <ui.Tag>[];
      int corruptedCount = 0;

      for (final row in rows) {
        try {
          final data = await encryptionService.decryptTag(
            row.encryptedBlob,
            expectedId: row.id,
            expectedSortOrder: row.sortOrder,
          );
          tags.add(_toTag(data));
        } catch (_) {
          corruptedCount++;
          continue;
        }
      }

      _lastCorruptedCount = corruptedCount;
      return tags;
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
}
