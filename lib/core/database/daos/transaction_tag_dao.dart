import 'package:drift/drift.dart';

import '../app_database.dart';

part 'transaction_tag_dao.g.dart';

/// Data Access Object for transaction-tag junction table operations.
@DriftAccessor(tables: [TransactionTags])
class TransactionTagDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionTagDaoMixin {
  TransactionTagDao(super.db);

  /// Add a tag to a transaction
  Future<void> addTag({
    required String transactionId,
    required String tagId,
  }) async {
    await into(transactionTags).insert(
      TransactionTagsCompanion.insert(
        transactionId: transactionId,
        tagId: tagId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Remove a tag from a transaction
  Future<void> removeTag({
    required String transactionId,
    required String tagId,
  }) async {
    await (delete(transactionTags)
          ..where((t) => t.transactionId.equals(transactionId))
          ..where((t) => t.tagId.equals(tagId)))
        .go();
  }

  /// Get all tag IDs for a transaction
  Future<List<String>> getTagIdsForTransaction(String transactionId) async {
    final rows = await (select(transactionTags)
          ..where((t) => t.transactionId.equals(transactionId)))
        .get();
    return rows.map((r) => r.tagId).toList();
  }

  /// Get all transaction IDs for a tag
  Future<List<String>> getTransactionIdsForTag(String tagId) async {
    final rows = await (select(transactionTags)
          ..where((t) => t.tagId.equals(tagId)))
        .get();
    return rows.map((r) => r.transactionId).toList();
  }

  /// Set the tags for a transaction (replaces all existing)
  Future<void> setTagsForTransaction(
    String transactionId,
    List<String> tagIds,
  ) async {
    // Remove all existing tags
    await (delete(transactionTags)
          ..where((t) => t.transactionId.equals(transactionId)))
        .go();

    // Add new tags
    for (final tagId in tagIds) {
      await addTag(transactionId: transactionId, tagId: tagId);
    }
  }

  /// Remove all tags for a specific tag ID (when deleting a tag)
  Future<void> removeAllForTag(String tagId) async {
    await (delete(transactionTags)
          ..where((t) => t.tagId.equals(tagId)))
        .go();
  }

  /// Remove all tags for a specific transaction
  Future<void> removeAllForTransaction(String transactionId) async {
    await (delete(transactionTags)
          ..where((t) => t.transactionId.equals(transactionId)))
        .go();
  }

  /// Delete all entries
  Future<void> deleteAll() async {
    await delete(transactionTags).go();
  }
}
