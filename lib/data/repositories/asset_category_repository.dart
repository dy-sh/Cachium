import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/assets/data/models/asset_category.dart' as ui;
import '../encryption/asset_category_data.dart';

/// Repository for managing encrypted asset category storage.
class AssetCategoryRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'AssetCategory';

  int _lastCorruptedCount = 0;
  int get lastCorruptedCount => _lastCorruptedCount;

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
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<ui.AssetCategory?> getCategory(String id) async {
    final row = await database.getAssetCategory(id);
    if (row == null) return null;

    try {
      final data = await encryptionService.decryptAssetCategory(
        row.encryptedBlob,
        expectedId: row.id,
        expectedCreatedAtMillis: row.createdAt,
      );
      return _toCategory(data);
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

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final data = await encryptionService.decryptAssetCategory(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            return _toCategory(data);
          } catch (e) {
            debugPrint('WARNING: Corrupted asset category row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      _lastCorruptedCount = corruptedCount;
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
