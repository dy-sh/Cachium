import 'package:drift/drift.dart';

import '../app_database.dart';

part 'asset_dao.g.dart';

/// Data Access Object for asset operations.
@DriftAccessor(tables: [Assets])
class AssetDao extends DatabaseAccessor<AppDatabase>
    with _$AssetDaoMixin {
  AssetDao(super.db);

  /// Insert a new asset row
  Future<void> insert({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(assets).insert(
      AssetsCompanion.insert(
        id: id,
        createdAt: createdAt,
        sortOrder: Value(sortOrder),
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
    );
  }

  /// Insert or update an asset row (upsert)
  Future<void> upsert({
    required String id,
    required int createdAt,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) async {
    await into(assets).insert(
      AssetsCompanion(
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

  /// Update an existing asset row
  Future<void> updateRow({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(assets)..where((a) => a.id.equals(id))).write(
      AssetsCompanion(
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  /// Update only the sort order of an asset
  Future<void> updateSortOrder(String id, int sortOrder) async {
    await (update(assets)..where((a) => a.id.equals(id))).write(
      AssetsCompanion(
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Soft delete an asset (set isDeleted = true)
  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(assets)..where((a) => a.id.equals(id))).write(
      AssetsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  /// Get a single asset by ID (only if not deleted)
  Future<Asset?> getById(String id) async {
    return (select(assets)
          ..where((a) => a.id.equals(id))
          ..where((a) => a.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all non-deleted assets ordered by sortOrder ascending
  Future<List<Asset>> getAll() async {
    return (select(assets)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .get();
  }

  /// Watch all non-deleted assets (for reactive UI)
  Stream<List<Asset>> watchAll() {
    return (select(assets)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .watch();
  }

  /// Check if any assets exist
  Future<bool> hasAny() async {
    final count = await (selectOnly(assets)
          ..addColumns([assets.id.count()]))
        .map((row) => row.read(assets.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  /// Delete all assets from the database
  Future<void> deleteAll() async {
    await delete(assets).go();
  }
}
