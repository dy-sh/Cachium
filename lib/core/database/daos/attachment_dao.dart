import 'package:drift/drift.dart';

import '../app_database.dart';

part 'attachment_dao.g.dart';

/// Data Access Object for attachment operations.
@DriftAccessor(tables: [Attachments])
class AttachmentDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentDaoMixin {
  AttachmentDao(super.db);

  Future<void> insert({
    required String id,
    required String transactionId,
    required int createdAt,
    required int lastUpdatedAt,
    required Uint8List encryptedBlob,
  }) async {
    await into(attachments).insert(
      AttachmentsCompanion.insert(
        id: id,
        transactionId: transactionId,
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
    await (update(attachments)..where((a) => a.id.equals(id))).write(
      AttachmentsCompanion(
        lastUpdatedAt: Value(lastUpdatedAt),
        encryptedBlob: Value(encryptedBlob),
      ),
    );
  }

  Future<void> softDelete(String id, int lastUpdatedAt) async {
    await (update(attachments)..where((a) => a.id.equals(id))).write(
      AttachmentsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  Future<AttachmentRow?> getById(String id) async {
    return (select(attachments)
          ..where((a) => a.id.equals(id))
          ..where((a) => a.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<List<AttachmentRow>> getByTransactionId(
      String transactionId) async {
    return (select(attachments)
          ..where((a) => a.transactionId.equals(transactionId))
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .get();
  }

  Stream<List<AttachmentRow>> watchByTransactionId(
      String transactionId) {
    return (select(attachments)
          ..where((a) => a.transactionId.equals(transactionId))
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .watch();
  }

  Future<List<AttachmentRow>> getAll() async {
    return (select(attachments)
          ..where((a) => a.isDeleted.equals(false)))
        .get();
  }

  Future<void> softDeleteByTransactionId(
      String transactionId, int lastUpdatedAt) async {
    await (update(attachments)
          ..where((a) => a.transactionId.equals(transactionId))
          ..where((a) => a.isDeleted.equals(false)))
        .write(
      AttachmentsCompanion(
        isDeleted: const Value(true),
        lastUpdatedAt: Value(lastUpdatedAt),
      ),
    );
  }

  Future<void> deleteAll() async {
    await delete(attachments).go();
  }
}
