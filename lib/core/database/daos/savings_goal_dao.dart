import 'package:drift/drift.dart';

import '../app_database.dart';

part 'savings_goal_dao.g.dart';

@DriftAccessor(tables: [SavingsGoals])
class SavingsGoalDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsGoalDaoMixin {
  SavingsGoalDao(super.db);

  Future<void> insert({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(savingsGoals).insert(
      SavingsGoalsCompanion.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
      ),
    );
  }

  Future<void> updateRow({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  Future<List<SavingsGoalRow>> getAll() async {
    return (select(savingsGoals)
          ..where((g) => g.isDeleted.equals(false))
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .get();
  }

  Stream<List<SavingsGoalRow>> watchAll() {
    return (select(savingsGoals)
          ..where((g) => g.isDeleted.equals(false))
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  Future<void> deleteAll() async {
    await delete(savingsGoals).go();
  }
}
