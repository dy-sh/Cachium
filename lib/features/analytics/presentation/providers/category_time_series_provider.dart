import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/category_time_series.dart';
import 'filtered_transactions_provider.dart';
import 'analytics_filter_provider.dart';

final selectedComparisonCategoryIdsProvider = StateProvider<Set<String>>((ref) => {});

final categoryTimeSeriesProvider = Provider<List<CategoryTimeSeries>>((ref) {
  final selectedIds = ref.watch(selectedComparisonCategoryIdsProvider);
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final filter = ref.watch(analyticsFilterProvider);

  final categories = categoriesAsync.valueOrNull;
  if (categories == null || selectedIds.isEmpty) return [];

  final catMap = <String, Category>{};
  for (final c in categories) {
    catMap[c.id] = c;
  }

  final start = filter.dateRange.start;
  final end = filter.dateRange.end;
  final days = end.difference(start).inDays + 1;

  // Determine grouping
  String Function(DateTime) getKey;
  String Function(DateTime) getLabel;
  if (days <= 14) {
    getKey = (d) => '${d.year}-${d.month}-${d.day}';
    getLabel = (d) => DateFormat('d MMM').format(d);
  } else if (days <= 90) {
    getKey = (d) {
      final weekStart = d.subtract(Duration(days: d.weekday - 1));
      return '${weekStart.year}-${weekStart.month}-${weekStart.day}';
    };
    getLabel = (d) {
      final weekStart = d.subtract(Duration(days: d.weekday - 1));
      return DateFormat('d MMM').format(weekStart);
    };
  } else {
    getKey = (d) => '${d.year}-${d.month}';
    getLabel = (d) => DateFormat('MMM yy').format(d);
  }

  // Build ordered period keys
  final orderedKeys = <String>[];
  final keyToDate = <String, DateTime>{};
  final keyToLabel = <String, String>{};
  var cursor = start;
  while (!cursor.isAfter(end)) {
    final k = getKey(cursor);
    if (!keyToDate.containsKey(k)) {
      orderedKeys.add(k);
      keyToDate[k] = cursor;
      keyToLabel[k] = getLabel(cursor);
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  // Group amounts per category per period
  final Map<String, Map<String, double>> catPeriodAmounts = {};
  for (final id in selectedIds) {
    catPeriodAmounts[id] = {};
  }

  for (final tx in transactions) {
    if (!selectedIds.contains(tx.categoryId)) continue;
    final k = getKey(tx.date);
    catPeriodAmounts[tx.categoryId] ??= {};
    catPeriodAmounts[tx.categoryId]![k] = (catPeriodAmounts[tx.categoryId]![k] ?? 0) + tx.amount;
  }

  return selectedIds.where((id) => catMap.containsKey(id)).map((id) {
    final cat = catMap[id]!;
    final amounts = catPeriodAmounts[id] ?? {};
    return CategoryTimeSeries(
      categoryId: id,
      name: cat.name,
      colorIndex: cat.colorIndex,
      points: orderedKeys.map((k) {
        return TimeSeriesPoint(
          date: keyToDate[k]!,
          label: keyToLabel[k]!,
          amount: amounts[k] ?? 0,
        );
      }).toList(),
    );
  }).toList();
});
