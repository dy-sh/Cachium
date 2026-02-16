import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/asset.dart';

class AssetsNotifier extends AsyncNotifier<List<Asset>> {
  final _uuid = const Uuid();

  @override
  Future<List<Asset>> build() async {
    final repo = ref.watch(assetRepositoryProvider);
    final assets = await repo.getAllAssets();
    // Sort by sortOrder
    assets.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return assets;
  }

  /// Add a new asset. Returns the new asset's ID.
  Future<String> addAsset({
    required String name,
    required IconData icon,
    required int colorIndex,
    String? note,
  }) async {
    final previousState = state;

    try {
      final repo = ref.read(assetRepositoryProvider);

      // Assign sortOrder = max + 1
      final currentAssets = state.valueOrNull ?? [];
      final maxSortOrder = currentAssets.isEmpty
          ? -1
          : currentAssets.map((a) => a.sortOrder).reduce((a, b) => a > b ? a : b);

      final asset = Asset(
        id: _uuid.v4(),
        name: name,
        icon: icon,
        colorIndex: colorIndex,
        note: note,
        sortOrder: maxSortOrder + 1,
        createdAt: DateTime.now(),
      );

      state = state.whenData((assets) => [...assets, asset]);
      await repo.createAsset(asset);
      return asset.id;
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.create(entityType: 'Asset', cause: e),
        st,
      );
    }
  }

  /// Update an existing asset.
  Future<void> updateAsset(Asset asset) async {
    final previousState = state;

    try {
      final repo = ref.read(assetRepositoryProvider);

      state = state.whenData(
        (assets) => assets.map((a) => a.id == asset.id ? asset : a).toList(),
      );

      await repo.updateAsset(asset);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Asset', entityId: asset.id, cause: e),
        st,
      );
    }
  }

  /// Delete an asset.
  Future<void> deleteAsset(String id) async {
    final previousState = state;

    try {
      final repo = ref.read(assetRepositoryProvider);

      state = state.whenData(
        (assets) => assets.where((a) => a.id != id).toList(),
      );

      await repo.deleteAsset(id);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'Asset', entityId: id, cause: e),
        st,
      );
    }
  }

  /// Move an asset to a new position in the list.
  Future<void> moveAssetToPosition(String assetId, int newIndex) async {
    final previousState = state;
    final assets = state.valueOrNull;
    if (assets == null) return;

    try {
      final repo = ref.read(assetRepositoryProvider);
      final db = ref.read(databaseProvider);

      // Build the reordered list
      final reordered = List<Asset>.from(assets);
      final oldIndex = reordered.indexWhere((a) => a.id == assetId);
      if (oldIndex == -1) return;

      final item = reordered.removeAt(oldIndex);
      reordered.insert(newIndex.clamp(0, reordered.length), item);

      // Assign new sort orders
      final updated = <Asset>[];
      for (int i = 0; i < reordered.length; i++) {
        updated.add(reordered[i].copyWith(sortOrder: i));
      }

      // Optimistic update
      state = AsyncData(updated);

      // Persist in a transaction
      await db.transaction(() async {
        for (final asset in updated) {
          if (asset.sortOrder != assets.firstWhere((a) => a.id == asset.id).sortOrder) {
            await repo.updateAsset(asset);
          }
        }
      });
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Asset', entityId: assetId, cause: e),
        st,
      );
    }
  }

  /// Refresh assets from database
  Future<void> refresh() async {
    try {
      final repo = ref.read(assetRepositoryProvider);
      final assets = await repo.getAllAssets();
      assets.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = AsyncData(assets);
    } catch (e, st) {
      state = AsyncError(
        e is AppException ? e : RepositoryException.fetch(entityType: 'Asset', cause: e),
        st,
      );
    }
  }
}

final assetsProvider =
    AsyncNotifierProvider<AssetsNotifier, List<Asset>>(() {
  return AssetsNotifier();
});

final assetByIdProvider = Provider.family<Asset?, String>((ref, id) {
  final assetsAsync = ref.watch(assetsProvider);
  final assets = assetsAsync.valueOrNull;
  if (assets == null) return null;
  try {
    return assets.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});

final activeAssetsProvider = Provider<List<Asset>>((ref) {
  final assetsAsync = ref.watch(assetsProvider);
  final assets = assetsAsync.valueOrNull ?? [];
  return assets.where((a) => a.status == AssetStatus.active).toList();
});

/// Checks if an asset name already exists (case-insensitive).
final assetNameExistsProvider = Provider.family<bool, ({String name, String? excludeId})>((ref, params) {
  final assetsAsync = ref.watch(assetsProvider);
  final assets = assetsAsync.valueOrNull ?? [];
  final nameLower = params.name.trim().toLowerCase();
  return assets.any((a) =>
    a.name.toLowerCase() == nameLower && a.id != params.excludeId
  );
});

/// Returns active asset IDs sorted by most recent transaction usage.
/// Assets without transactions appear last, sorted by creation date.
final recentlyUsedAssetIdsProvider = Provider<List<String>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  final assets = ref.watch(activeAssetsProvider);
  if (assets.isEmpty) return [];

  final Map<String, DateTime> lastUsedMap = {};
  if (transactions != null) {
    for (final tx in transactions) {
      if (tx.assetId == null) continue;
      final current = lastUsedMap[tx.assetId!];
      if (current == null || tx.createdAt.isAfter(current)) {
        lastUsedMap[tx.assetId!] = tx.createdAt;
      }
    }
  }

  final sortedAssets = List<Asset>.from(assets);
  sortedAssets.sort((a, b) {
    final aLastUsed = lastUsedMap[a.id];
    final bLastUsed = lastUsedMap[b.id];
    if (aLastUsed != null && bLastUsed != null) {
      return bLastUsed.compareTo(aLastUsed);
    }
    if (aLastUsed != null) return -1;
    if (bLastUsed != null) return 1;
    return b.createdAt.compareTo(a.createdAt);
  });

  return sortedAssets.map((a) => a.id).toList();
});

/// Returns active assets that have been used with the given category family
/// (category + parent + siblings + children).
final assetsForCategoryProvider = Provider.family<List<Asset>, String?>((ref, categoryId) {
  final activeAssets = ref.watch(activeAssetsProvider);
  if (categoryId == null) return activeAssets;

  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrNull ?? [];
  final category = categories.where((c) => c.id == categoryId).firstOrNull;

  // Collect related category IDs: selected category + parent + siblings + children
  final relatedCategoryIds = <String>{categoryId};
  if (category?.parentId != null) {
    relatedCategoryIds.add(category!.parentId!);
    // Add sibling categories
    final siblings = categories.where((c) => c.parentId == category.parentId);
    relatedCategoryIds.addAll(siblings.map((c) => c.id));
  }
  // If this IS a parent, add its children
  final children = categories.where((c) => c.parentId == categoryId);
  relatedCategoryIds.addAll(children.map((c) => c.id));

  // Find asset IDs used with any of these categories
  final usedAssetIds = <String>{};
  for (final tx in transactions) {
    if (tx.assetId != null && relatedCategoryIds.contains(tx.categoryId)) {
      usedAssetIds.add(tx.assetId!);
    }
  }

  return activeAssets.where((a) => usedAssetIds.contains(a.id)).toList();
});

/// Net cost for an asset: total expenses minus total income.
final assetNetCostProvider = Provider.family<double, String>((ref, assetId) {
  final transactions = ref.watch(transactionsByAssetProvider(assetId));
  double totalSpent = 0;
  double totalIncome = 0;
  for (final tx in transactions) {
    if (tx.type == TransactionType.expense) {
      totalSpent += tx.amount;
    } else if (tx.type == TransactionType.income) {
      totalIncome += tx.amount;
    }
  }
  return totalSpent - totalIncome;
});

/// Count of linked transactions for an asset.
final assetTransactionCountProvider = Provider.family<int, String>((ref, assetId) {
  return ref.watch(transactionsByAssetProvider(assetId)).length;
});
