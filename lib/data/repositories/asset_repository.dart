import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/assets/data/models/asset.dart' as ui;
import '../encryption/asset_data.dart';
import 'corruption_tracker.dart';
import 'decryption_cache.dart';

/// Repository for managing encrypted asset storage.
///
/// Converts between UI Asset models and encrypted database records.
/// All sensitive data is encrypted before storage and decrypted on retrieval.
class AssetRepository with CorruptionTracker {
  final db.AppDatabase database;
  final EncryptionService encryptionService;
  final _decryptionCache = DecryptionCache<ui.Asset>();

  static const _entityType = 'Asset';

  AssetRepository({
    required this.database,
    required this.encryptionService,
  });

  /// Convert UI Asset to internal AssetData for encryption
  AssetData _toData(ui.Asset asset) {
    return AssetData(
      id: asset.id,
      name: asset.name,
      iconCodePoint: asset.icon.codePoint,
      iconFontFamily: asset.icon.fontFamily,
      iconFontPackage: asset.icon.fontPackage,
      colorIndex: asset.colorIndex,
      status: asset.status.name,
      soldDateMillis: asset.soldDate?.millisecondsSinceEpoch,
      salePrice: asset.salePrice,
      saleCurrencyCode: asset.saleCurrencyCode,
      note: asset.note,
      purchasePrice: asset.purchasePrice,
      purchaseCurrencyCode: asset.purchaseCurrencyCode,
      assetCategoryId: asset.assetCategoryId,
      purchaseDateMillis: asset.purchaseDate?.millisecondsSinceEpoch,
      sortOrder: asset.sortOrder,
      createdAtMillis: asset.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Convert internal AssetData to UI Asset
  ui.Asset _toAsset(AssetData data) {
    return ui.Asset(
      id: data.id,
      name: data.name,
      icon: IconData(
        data.iconCodePoint,
        fontFamily: data.iconFontFamily ?? 'lucide',
        fontPackage: data.iconFontPackage ?? 'lucide_icons',
      ),
      colorIndex: data.colorIndex,
      status: ui.AssetStatus.values.firstWhere(
        (s) => s.name == data.status,
        orElse: () => ui.AssetStatus.active,
      ),
      soldDate: data.soldDateMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(data.soldDateMillis!)
          : null,
      salePrice: data.salePrice,
      saleCurrencyCode: data.saleCurrencyCode,
      note: data.note,
      purchasePrice: data.purchasePrice,
      purchaseCurrencyCode: data.purchaseCurrencyCode,
      assetCategoryId: data.assetCategoryId,
      purchaseDate: data.purchaseDateMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(data.purchaseDateMillis!)
          : null,
      sortOrder: data.sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  /// Create a new asset (encrypt and insert)
  Future<void> createAsset(ui.Asset asset) async {
    try {
      final data = _toData(asset);
      final encryptedBlob = await encryptionService.encryptAsset(data);

      await database.insertAsset(
        id: asset.id,
        createdAt: asset.createdAt.millisecondsSinceEpoch,
        sortOrder: asset.sortOrder,
        lastUpdatedAt: asset.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(asset.id);
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Create or update an asset (encrypt and upsert)
  Future<void> upsertAsset(ui.Asset asset) async {
    try {
      final data = _toData(asset);
      final encryptedBlob = await encryptionService.encryptAsset(data);

      await database.upsertAsset(
        id: asset.id,
        createdAt: asset.createdAt.millisecondsSinceEpoch,
        sortOrder: asset.sortOrder,
        lastUpdatedAt: asset.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(asset.id);
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  /// Get a single asset by ID (fetch, decrypt, verify)
  Future<ui.Asset?> getAsset(String id) async {
    final row = await database.getAsset(id);
    if (row == null) return null;

    try {
      final cached = _decryptionCache.get(row.id, row.encryptedBlob);
      if (cached != null) return cached;
      final data = await encryptionService.decryptAsset(
        row.encryptedBlob,
        expectedId: row.id,
        expectedCreatedAtMillis: row.createdAt,
      );
      final result = _toAsset(data);
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

  /// Get all non-deleted assets
  Future<List<ui.Asset>> getAllAssets() async {
    try {
      final rows = await database.getAllAssets();
      int corruptedCount = 0;

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final cached = _decryptionCache.get(row.id, row.encryptedBlob);
            if (cached != null) return cached;
            final data = await encryptionService.decryptAsset(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            final result = _toAsset(data);
            _decryptionCache.put(row.id, row.encryptedBlob, result);
            return result;
          } catch (e) {
            debugPrint('WARNING: Corrupted asset row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      updateCorruptedCount(corruptedCount);
      return results.whereType<ui.Asset>().toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  /// Update an existing asset (re-encrypt and update)
  Future<void> updateAsset(ui.Asset asset) async {
    try {
      final data = _toData(asset);
      final encryptedBlob = await encryptionService.encryptAsset(data);

      await database.updateAsset(
        id: asset.id,
        sortOrder: asset.sortOrder,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(asset.id);
    } catch (e) {
      throw RepositoryException.update(
        entityType: _entityType,
        entityId: asset.id,
        cause: e,
      );
    }
  }

  /// Soft delete an asset (set isDeleted = true)
  Future<void> deleteAsset(String id) async {
    try {
      await database.softDeleteAsset(
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

  /// Watch all assets (for reactive UI)
  Stream<List<ui.Asset>> watchAllAssets() {
    return database.watchAllAssets().asyncMap((rows) async {
      int corruptedCount = 0;

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final cached = _decryptionCache.get(row.id, row.encryptedBlob);
            if (cached != null) return cached;
            final data = await encryptionService.decryptAsset(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            final result = _toAsset(data);
            _decryptionCache.put(row.id, row.encryptedBlob, result);
            return result;
          } catch (e) {
            debugPrint('WARNING: Corrupted asset row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      updateCorruptedCount(corruptedCount);
      return results.whereType<ui.Asset>().toList();
    });
  }

  /// Check if any assets exist in the database
  Future<bool> hasAssets() async {
    return database.hasAssets();
  }
}
