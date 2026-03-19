import 'package:drift/drift.dart';

import '../app_database.dart';

part 'notification_log_dao.g.dart';

/// Data Access Object for notification log operations.
@DriftAccessor(tables: [NotificationLog])
class NotificationLogDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationLogDaoMixin {
  NotificationLogDao(super.db);

  /// Insert a notification log entry
  Future<void> insert({
    required String id,
    required String type,
    String? referenceId,
    required int sentAt,
    int? scheduledFor,
  }) async {
    await into(notificationLog).insert(
      NotificationLogCompanion.insert(
        id: id,
        type: type,
        referenceId: Value(referenceId),
        sentAt: sentAt,
        scheduledFor: Value(scheduledFor),
      ),
    );
  }

  /// Get all log entries ordered by sentAt descending
  Future<List<NotificationLogRow>> getAll() async {
    return (select(notificationLog)
          ..orderBy([(n) => OrderingTerm.desc(n.sentAt)]))
        .get();
  }

  /// Get log entries by type
  Future<List<NotificationLogRow>> getByType(String type) async {
    return (select(notificationLog)
          ..where((n) => n.type.equals(type))
          ..orderBy([(n) => OrderingTerm.desc(n.sentAt)]))
        .get();
  }

  /// Check if a notification was sent recently for a reference
  Future<bool> wasSentRecently({
    required String type,
    required String referenceId,
    required Duration within,
  }) async {
    final cutoff = DateTime.now().subtract(within).millisecondsSinceEpoch;
    final result = await (select(notificationLog)
          ..where((n) => n.type.equals(type))
          ..where((n) => n.referenceId.equals(referenceId))
          ..where((n) => n.sentAt.isBiggerOrEqualValue(cutoff)))
        .get();
    return result.isNotEmpty;
  }

  /// Delete all log entries
  Future<void> deleteAll() async {
    await delete(notificationLog).go();
  }

  /// Delete entries older than a given duration
  Future<void> cleanupOlderThan(Duration olderThan) async {
    final cutoff = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
    await (delete(notificationLog)
          ..where((n) => n.sentAt.isSmallerThanValue(cutoff)))
        .go();
  }
}
