import 'package:drift/drift.dart';

import '../app_database.dart';

part 'asset_category_dao.g.dart';

/// Data Access Object for asset category operations.
@DriftAccessor(tables: [AssetCategories])
class AssetCategoryDao extends DatabaseAccessor<AppDatabase>
    with _$AssetCategoryDaoMixin {
  AssetCategoryDao(super.db);

  /// Insert a new asset category row
  Future<void> insert({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(assetCategories).insert(
      AssetCategoriesCompanion.insert(
        id: id,
        createdAt: createdAt,
        sortOrder: Value(sortOrder),
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
    );
  }

  /// Insert or update an asset category row (upsert)
  Future<void> upsert({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) async {
    await into(assetCategories).insert(
      AssetCategoriesCompanion(
        id: Value(id),
        createdAt: Value(createdAt),
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
        isDeleted: Value(isDeleted),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Update an existing asset category row
  Future<void> updateRow({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(assetCategories)..where((a) => a.id.equals(id))).write(
      AssetCategoriesCompanion(
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  /// Soft delete an asset category (set isDeleted = true)
  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(assetCategories)..where((a) => a.id.equals(id))).write(
      AssetCategoriesCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  /// Get a single asset category by ID (only if not deleted)
  Future<AssetCategoryRow?> getById(String id) async {
    return (select(assetCategories)
          ..where((a) => a.id.equals(id))
          ..where((a) => a.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all non-deleted asset categories ordered by sortOrder ascending
  Future<List<AssetCategoryRow>> getAll() async {
    return (select(assetCategories)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .get();
  }

  /// Watch all non-deleted asset categories (for reactive UI)
  Stream<List<AssetCategoryRow>> watchAll() {
    return (select(assetCategories)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .watch();
  }

  /// Check if any asset categories exist
  Future<bool> hasAny() async {
    final count = await (selectOnly(assetCategories)
          ..addColumns([assetCategories.id.count()]))
        .map((row) => row.read(assetCategories.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  /// Delete all asset categories from the database
  Future<void> deleteAll() async {
    await delete(assetCategories).go();
  }
}
