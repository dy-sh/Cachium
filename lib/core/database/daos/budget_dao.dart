import 'package:drift/drift.dart';

import '../app_database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase>
    with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Future<void> insert({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(budgets).insert(
      BudgetsCompanion.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
    );
  }

  Future<void> upsert({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
    bool isDeleted = false,
  }) async {
    await into(budgets).insert(
      BudgetsCompanion(
        id: Value(id),
        createdAt: Value(createdAt),
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
        isDeleted: Value(isDeleted),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateRow({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  Future<BudgetRow?> getById(String id) async {
    return (select(budgets)
          ..where((b) => b.id.equals(id))
          ..where((b) => b.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<List<BudgetRow>> getAll() async {
    return (select(budgets)
          ..where((b) => b.isDeleted.equals(false))
          ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
        .get();
  }

  Stream<List<BudgetRow>> watchAll() {
    return (select(budgets)
          ..where((b) => b.isDeleted.equals(false))
          ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
        .watch();
  }

  Future<bool> hasAny() async {
    final count = await (selectOnly(budgets)
          ..addColumns([budgets.id.count()]))
        .map((row) => row.read(budgets.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  Future<void> deleteAll() async {
    await delete(budgets).go();
  }
}
