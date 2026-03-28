import 'dart:convert';

import '../../core/database/app_database.dart';
import '../../features/analytics/data/models/net_worth_snapshot.dart';

class NetWorthSnapshotRepository {
  final AppDatabase database;

  NetWorthSnapshotRepository({required this.database});

  Future<void> save(NetWorthSnapshot snapshot) async {
    final balancesJson = jsonEncode(snapshot.perAccountBalances);
    await database.netWorthSnapshotDao.upsert(
      id: snapshot.id,
      date: snapshot.date.millisecondsSinceEpoch,
      netWorth: snapshot.netWorth,
      totalHoldings: snapshot.totalHoldings,
      totalLiabilities: snapshot.totalLiabilities,
      perAccountBalancesJson: balancesJson,
      mainCurrencyCode: snapshot.mainCurrencyCode,
    );
  }

  Future<List<NetWorthSnapshot>> getAll() async {
    final rows = await database.netWorthSnapshotDao.getAll();
    return rows.map(_fromRow).toList();
  }

  Future<NetWorthSnapshot?> getForMonth(DateTime monthStart) async {
    final ms = DateTime(monthStart.year, monthStart.month, 1).millisecondsSinceEpoch;
    final row = await database.netWorthSnapshotDao.getByMonth(ms);
    return row != null ? _fromRow(row) : null;
  }

  Future<void> deleteAll() async {
    await database.netWorthSnapshotDao.deleteAll();
  }

  NetWorthSnapshot _fromRow(NetWorthSnapshotRow row) {
    Map<String, double> balances = {};
    try {
      final decoded = jsonDecode(row.perAccountBalancesJson) as Map<String, dynamic>;
      balances = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      // Malformed JSON — use empty balances map
    }

    return NetWorthSnapshot(
      id: row.id,
      date: DateTime.fromMillisecondsSinceEpoch(row.date),
      netWorth: row.netWorth,
      totalHoldings: row.totalHoldings,
      totalLiabilities: row.totalLiabilities,
      perAccountBalances: balances,
      mainCurrencyCode: row.mainCurrencyCode,
    );
  }
}
