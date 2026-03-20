import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';

/// Maximum number of recent searches to store.
const _maxRecentSearches = 10;

/// Persists recent search queries to the database settings table.
class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  static const _storageId = 'search_history';

  @override
  Future<List<String>> build() async {
    final db = ref.watch(databaseProvider);
    final row = await db.getSettings(_storageId);
    if (row == null) return [];
    try {
      final list = (jsonDecode(row.jsonData) as List).cast<String>();
      return list.take(_maxRecentSearches).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a query to the top of recent searches (deduplicates).
  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = state.valueOrNull ?? [];
    final updated = [
      trimmed,
      ...current.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxRecentSearches).toList();

    state = AsyncData(updated);
    await _persist(updated);
  }

  /// Remove a single search from history.
  Future<void> removeSearch(String query) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((q) => q != query).toList();
    state = AsyncData(updated);
    await _persist(updated);
  }

  /// Clear all recent searches.
  Future<void> clearAll() async {
    state = const AsyncData([]);
    await _persist([]);
  }

  Future<void> _persist(List<String> searches) async {
    try {
      final db = ref.read(databaseProvider);
      await db.upsertSettings(
        id: _storageId,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        jsonData: jsonEncode(searches),
      );
    } catch (_) {
      // Silent failure — search history is non-critical
    }
  }
}

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(() {
  return SearchHistoryNotifier();
});
