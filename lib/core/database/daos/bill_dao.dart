import 'package:drift/drift.dart';

import '../app_database.dart';

part 'bill_dao.g.dart';

@DriftAccessor(tables: [Bills])
class BillDao extends DatabaseAccessor<AppDatabase> with _$BillDaoMixin {
  BillDao(super.db);

  Future<void> insert({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(bills).insert(
      BillsCompanion.insert(
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
    await into(bills).insertOnConflictUpdate(
      BillsCompanion.insert(
        id: id,
        createdAt: createdAt,
        lastUpdatedAt: lastUpdatedAt,
        encryptedBlob: encryptedBlob,
        isDeleted: Value(isDeleted),
      ),
    );
  }

  Future<void> updateRow({
    required String id,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await (update(bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  Future<List<BillRow>> getAll() async {
    return (select(bills)
          ..where((b) => b.isDeleted.equals(false))
          ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
        .get();
  }

  Stream<List<BillRow>> watchAll() {
    return (select(bills)
          ..where((b) => b.isDeleted.equals(false))
          ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
        .watch();
  }

  Future<void> deleteAll() async {
    await delete(bills).go();
  }
}
