import 'package:drift/drift.dart';

import '../app_database.dart';

part 'transaction_template_dao.g.dart';

@DriftAccessor(tables: [TransactionTemplates])
class TransactionTemplateDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionTemplateDaoMixin {
  TransactionTemplateDao(super.db);

  Future<void> insert({
    required String id,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(transactionTemplates).insert(
      TransactionTemplatesCompanion.insert(
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
    await (update(transactionTemplates)..where((r) => r.id.equals(id))).write(
      TransactionTemplatesCompanion(
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(transactionTemplates)..where((r) => r.id.equals(id))).write(
      TransactionTemplatesCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  Future<List<TransactionTemplateRow>> getAll() async {
    return (select(transactionTemplates)
          ..where((r) => r.isDeleted.equals(false))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
  }

  Stream<List<TransactionTemplateRow>> watchAll() {
    return (select(transactionTemplates)
          ..where((r) => r.isDeleted.equals(false))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .watch();
  }

  Future<void> deleteAll() async {
    await delete(transactionTemplates).go();
  }
}
