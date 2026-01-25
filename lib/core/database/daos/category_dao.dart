import 'package:drift/drift.dart';

import '../app_database.dart';

part 'category_dao.g.dart';

/// Data Access Object for category operations.
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Insert a new category row
  Future<void> insert({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: id,
        sortOrder: sortOrder,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
    );
  }

  /// Insert or update a category row (upsert)
  Future<void> upsert({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) async {
    await into(categories).insert(
      CategoriesCompanion(
        id: Value(id),
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
        isDeleted: Value(isDeleted),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Update an existing category row
  Future<void> updateRow({
    required String id,
    required int sortOrder,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        sortOrder: Value(sortOrder),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  /// Soft delete a category (set isDeleted = true)
  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  /// Get a single category by ID (only if not deleted)
  Future<CategoryRow?> getById(String id) async {
    return (select(categories)
          ..where((c) => c.id.equals(id))
          ..where((c) => c.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all non-deleted categories ordered by sortOrder
  Future<List<CategoryRow>> getAll() async {
    return (select(categories)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Watch all non-deleted categories (for reactive UI)
  Stream<List<CategoryRow>> watchAll() {
    return (select(categories)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Check if any categories exist
  Future<bool> hasAny() async {
    final count = await (selectOnly(categories)
          ..addColumns([categories.id.count()]))
        .map((row) => row.read(categories.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  /// Delete all categories from the database
  Future<void> deleteAll() async {
    await delete(categories).go();
  }
}
