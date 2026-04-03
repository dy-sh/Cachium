import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/utils/decrypt_batch.dart';
import '../../features/assets/data/models/asset_category.dart' as ui;
import '../encryption/asset_category_data.dart';
import 'corruption_tracker.dart';
import 'decryption_cache.dart';

/// Repository for managing encrypted asset category storage.
class AssetCategoryRepository with CorruptionTracker {
  final db.AppDatabase database;
  final EncryptionService encryptionService;
  final _decryptionCache = DecryptionCache<ui.AssetCategory>();

  static const _entityType = 'AssetCategory';

  AssetCategoryRepository({
    required this.database,
    required this.encryptionService,
  });

  AssetCategoryData _toData(ui.AssetCategory category) {
    return AssetCategoryData(
      id: category.id,
      name: category.name,
      iconCodePoint: category.icon.codePoint,
      iconFontFamily: category.icon.fontFamily,
      iconFontPackage: category.icon.fontPackage,
      colorIndex: category.colorIndex,
      sortOrder: category.sortOrder,
      createdAtMillis: category.createdAt.millisecondsSinceEpoch,
    );
  }

  ui.AssetCategory _toCategory(AssetCategoryData data) {
    return ui.AssetCategory(
      id: data.id,
      name: data.name,
      icon: IconData(
        data.iconCodePoint,
        fontFamily: data.iconFontFamily ?? 'lucide',
        fontPackage: data.iconFontPackage ?? 'lucide_icons',
      ),
      colorIndex: data.colorIndex,
      sortOrder: data.sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  Future<void> createCategory(ui.AssetCategory category) async {
    try {
      final data = _toData(category);
      final encryptedBlob = await encryptionService.encryptAssetCategory(data);

      await database.insertAssetCategory(
        id: category.id,
        createdAt: category.createdAt.millisecondsSinceEpoch,
        sortOrder: category.sortOrder,
        lastUpdatedAt: category.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(category.id);
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<ui.AssetCategory?> getCategory(String id) async {
    final row = await database.getAssetCategory(id);
    if (row == null) return null;

    try {
      final cached = _decryptionCache.get(row.id, row.encryptedBlob);
      if (cached != null) return cached;
      final data = await encryptionService.decryptAssetCategory(
        row.encryptedBlob,
        expectedId: row.id,
        expectedCreatedAtMillis: row.createdAt,
      );
      final result = _toCategory(data);
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

  Future<List<ui.AssetCategory>> getAllCategories() async {
    try {
      final rows = await database.getAllAssetCategories();
      int corruptedCount = 0;

      final results = await decryptBatch(
        rows.map((row) => () async {
          try {
            final cached = _decryptionCache.get(row.id, row.encryptedBlob);
            if (cached != null) return cached;
            final data = await encryptionService.decryptAssetCategory(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            final result = _toCategory(data);
            _decryptionCache.put(row.id, row.encryptedBlob, result);
            return result;
          } catch (e) {
            debugPrint('WARNING: Corrupted asset category row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      updateCorruptedCount(corruptedCount);
      return results.whereType<ui.AssetCategory>().toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  Future<void> updateCategory(ui.AssetCategory category) async {
    try {
      final data = _toData(category);
      final encryptedBlob = await encryptionService.encryptAssetCategory(data);

      await database.updateAssetCategory(
        id: category.id,
        sortOrder: category.sortOrder,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(category.id);
    } catch (e) {
      throw RepositoryException.update(
        entityType: _entityType,
        entityId: category.id,
        cause: e,
      );
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await database.softDeleteAssetCategory(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
      _decryptionCache.invalidate(id);
    } catch (e) {
      throw RepositoryException.delete(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  Future<bool> hasCategories() async {
    return database.hasAssetCategories();
  }
}
