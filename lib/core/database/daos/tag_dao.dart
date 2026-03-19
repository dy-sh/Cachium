import 'package:drift/drift.dart';

import '../app_database.dart';

part 'tag_dao.g.dart';

/// Data Access Object for tag operations.
@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  /// Insert a new tag row
  Future<void> insert({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(tags).insert(
      TagsCompanion.insert(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
    );
  }

  /// Insert or update a tag row (upsert)
  Future<void> upsert({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) async {
    await into(tags).insert(
      TagsCompanion(
        id: Value(id),
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
        isDeleted: Value(isDeleted),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Update an existing tag row
  Future<void> updateRow({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  /// Soft delete a tag
  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  /// Get a single tag by ID (only if not deleted)
  Future<TagRow?> getById(String id) async {
    return (select(tags)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all non-deleted tags ordered by sortOrder
  Future<List<TagRow>> getAll() async {
    return (select(tags)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Watch all non-deleted tags (for reactive UI)
  Stream<List<TagRow>> watchAll() {
    return (select(tags)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Check if any tags exist
  Future<bool> hasAny() async {
    final count = await (selectOnly(tags)
          ..addColumns([tags.id.count()]))
        .map((row) => row.read(tags.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  /// Delete all tags from the database
  Future<void> deleteAll() async {
    await delete(tags).go();
  }
}
