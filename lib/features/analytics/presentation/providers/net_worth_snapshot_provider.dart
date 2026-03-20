import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/models/net_worth_snapshot.dart';

final netWorthSnapshotsProvider = FutureProvider<List<NetWorthSnapshot>>((ref) async {
  final repo = ref.watch(netWorthSnapshotRepositoryProvider);
  return repo.getAll();
});

final netWorthTrendProvider = Provider<double?>((ref) {
  final snapshotsAsync = ref.watch(netWorthSnapshotsProvider);
  final snapshots = snapshotsAsync.valueOrNull;
  if (snapshots == null || snapshots.length < 2) return null;

  final previous = snapshots[snapshots.length - 2];
  final current = snapshots.last;

  if (previous.netWorth == 0) return current.netWorth > 0 ? 100.0 : 0.0;

  return ((current.netWorth - previous.netWorth) / previous.netWorth.abs()) * 100;
});
