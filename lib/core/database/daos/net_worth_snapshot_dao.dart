import 'package:drift/drift.dart';

import '../app_database.dart';

part 'net_worth_snapshot_dao.g.dart';

@DriftAccessor(tables: [NetWorthSnapshots])
class NetWorthSnapshotDao extends DatabaseAccessor<AppDatabase>
    with _$NetWorthSnapshotDaoMixin {
  NetWorthSnapshotDao(super.db);

  Future<void> upsert({
    required String id,
    required int date,
    required double netWorth,
    required double totalHoldings,
    required double totalLiabilities,
    required String perAccountBalancesJson,
    required String mainCurrencyCode,
  }) async {
    await into(netWorthSnapshots).insertOnConflictUpdate(
      NetWorthSnapshotsCompanion.insert(
        id: id,
        date: date,
        netWorth: netWorth,
        totalHoldings: totalHoldings,
        totalLiabilities: totalLiabilities,
        perAccountBalancesJson: perAccountBalancesJson,
        mainCurrencyCode: mainCurrencyCode,
      ),
    );
  }

  Future<List<NetWorthSnapshotRow>> getAll() async {
    return (select(netWorthSnapshots)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<NetWorthSnapshotRow?> getByMonth(int dateMs) async {
    final result = await (select(netWorthSnapshots)
          ..where((t) => t.date.equals(dateMs)))
        .get();
    return result.isEmpty ? null : result.first;
  }

  Future<void> deleteAll() async {
    await delete(netWorthSnapshots).go();
  }
}
