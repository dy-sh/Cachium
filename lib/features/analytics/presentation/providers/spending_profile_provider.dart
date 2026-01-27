import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/date_range_preset.dart';
import '../../data/models/spending_profile.dart';
import 'analytics_filter_provider.dart';
import 'period_comparison_provider.dart';

final spendingProfileProvider = Provider<List<SpendingProfile>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final periodA = ref.watch(comparisonPeriodAProvider);
  final periodB = ref.watch(comparisonPeriodBProvider);

  final transactions = transactionsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;
  if (transactions == null || categories == null) return [];

  final catMap = <String, Category>{};
  for (final c in categories) {
    catMap[c.id] = c;
  }

  // Only expense transactions, apply account filter
  List<Transaction> filterForRange(DateRange range) {
    return transactions.where((tx) {
      if (tx.type != TransactionType.expense) return false;
      if (!range.contains(tx.date)) return false;
      if (filter.hasAccountFilter && !filter.selectedAccountIds.contains(tx.accountId)) return false;
      return true;
    }).toList();
  }

  final txA = filterForRange(periodA);
  final txB = filterForRange(periodB);

  // Aggregate by category for each period
  Map<String, double> aggregate(List<Transaction> txs) {
    final map = <String, double>{};
    for (final tx in txs) {
      // Use parent category if exists
      final cat = catMap[tx.categoryId];
      final key = cat?.parentId ?? tx.categoryId;
      map[key] = (map[key] ?? 0) + tx.amount;
    }
    return map;
  }

  final amountsA = aggregate(txA);
  final amountsB = aggregate(txB);

  // Find top 6 categories by combined spend
  final allCatIds = {...amountsA.keys, ...amountsB.keys};
  final ranked = allCatIds.toList()
    ..sort((a, b) => ((amountsA[b] ?? 0) + (amountsB[b] ?? 0)).compareTo((amountsA[a] ?? 0) + (amountsB[a] ?? 0)));
  final topIds = ranked.take(6).toList();

  if (topIds.isEmpty) return [];

  // Find max for normalization
  double maxAmount = 0;
  for (final id in topIds) {
    final a = amountsA[id] ?? 0;
    final b = amountsB[id] ?? 0;
    if (a > maxAmount) maxAmount = a;
    if (b > maxAmount) maxAmount = b;
  }
  if (maxAmount == 0) maxAmount = 1;

  SpendingProfile buildProfile(String label, Map<String, double> amounts) {
    return SpendingProfile(
      label: label,
      axes: topIds.map((id) {
        final raw = amounts[id] ?? 0;
        return SpendingProfileAxis(
          categoryName: catMap[id]?.name ?? 'Unknown',
          value: raw / maxAmount,
          rawAmount: raw,
        );
      }).toList(),
    );
  }

  return [
    buildProfile('Period A', amountsA),
    buildProfile('Period B', amountsB),
  ];
});
