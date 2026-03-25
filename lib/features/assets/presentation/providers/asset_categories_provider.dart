import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/models/asset_category.dart';

class AssetCategoriesNotifier extends AsyncNotifier<List<AssetCategory>> {
  final _uuid = const Uuid();

  @override
  Future<List<AssetCategory>> build() async {
    final repo = ref.watch(assetCategoryRepositoryProvider);
    final categories = await repo.getAllCategories();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Seed defaults if empty
    if (categories.isEmpty) {
      final seeded = await _seedDefaults();
      return seeded;
    }

    return categories;
  }

  Future<List<AssetCategory>> _seedDefaults() async {
    final repo = ref.read(assetCategoryRepositoryProvider);
    final categories = <AssetCategory>[];

    for (int i = 0; i < DefaultAssetCategories.defaults.length; i++) {
      final def = DefaultAssetCategories.defaults[i];
      final category = AssetCategory(
        id: _uuid.v4(),
        name: def.name,
        icon: def.icon,
        colorIndex: def.colorIndex,
        sortOrder: i,
        createdAt: DateTime.now(),
      );
      await repo.createCategory(category);
      categories.add(category);
    }

    return categories;
  }

  Future<String> addCategory({
    required String name,
    required IconData icon,
    required int colorIndex,
  }) async {
    final previousState = state;

    try {
      final repo = ref.read(assetCategoryRepositoryProvider);

      final currentCategories = state.valueOrNull ?? [];
      final maxSortOrder = currentCategories.isEmpty
          ? -1
          : currentCategories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);

      final category = AssetCategory(
        id: _uuid.v4(),
        name: name,
        icon: icon,
        colorIndex: colorIndex,
        sortOrder: maxSortOrder + 1,
        createdAt: DateTime.now(),
      );

      state = state.whenData((categories) => [...categories, category]);
      await repo.createCategory(category);
      return category.id;
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.create(entityType: 'AssetCategory', cause: e),
        st,
      );
    }
  }

  Future<void> updateCategory(AssetCategory category) async {
    final previousState = state;

    try {
      final repo = ref.read(assetCategoryRepositoryProvider);

      state = state.whenData(
        (categories) => categories.map((c) => c.id == category.id ? category : c).toList(),
      );

      await repo.updateCategory(category);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'AssetCategory', entityId: category.id, cause: e),
        st,
      );
    }
  }

  Future<void> deleteCategory(String id) async {
    final previousState = state;

    try {
      final repo = ref.read(assetCategoryRepositoryProvider);

      state = state.whenData(
        (categories) => categories.where((c) => c.id != id).toList(),
      );

      await repo.deleteCategory(id);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'AssetCategory', entityId: id, cause: e),
        st,
      );
    }
  }

  Future<void> moveCategoryToPosition(String categoryId, int newIndex) async {
    final previousState = state;
    final categories = state.valueOrNull;
    if (categories == null) return;

    try {
      final repo = ref.read(assetCategoryRepositoryProvider);
      final db = ref.read(databaseProvider);

      final reordered = List<AssetCategory>.from(categories);
      final oldIndex = reordered.indexWhere((c) => c.id == categoryId);
      if (oldIndex == -1) return;

      final item = reordered.removeAt(oldIndex);
      reordered.insert(newIndex.clamp(0, reordered.length), item);

      final updated = <AssetCategory>[];
      for (int i = 0; i < reordered.length; i++) {
        updated.add(reordered[i].copyWith(sortOrder: i));
      }

      state = AsyncData(updated);

      await db.transaction(() async {
        for (final category in updated) {
          if (category.sortOrder != categories.firstWhere((c) => c.id == category.id).sortOrder) {
            await repo.updateCategory(category);
          }
        }
      });
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'AssetCategory', entityId: categoryId, cause: e),
        st,
      );
    }
  }
}

final assetCategoriesProvider =
    AsyncNotifierProvider<AssetCategoriesNotifier, List<AssetCategory>>(() {
  return AssetCategoriesNotifier();
});

final assetCategoryByIdProvider = Provider.family<AssetCategory?, String>((ref, id) {
  final categoriesAsync = ref.watch(assetCategoriesProvider);
  final categories = categoriesAsync.valueOrNull;
  if (categories == null) return null;
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

final assetCategoryNameExistsProvider = Provider.family<bool, ({String name, String? excludeId})>((ref, params) {
  final categoriesAsync = ref.watch(assetCategoriesProvider);
  final categories = categoriesAsync.valueOrNull ?? [];
  final nameLower = params.name.trim().toLowerCase();
  return categories.any((c) =>
    c.name.toLowerCase() == nameLower && c.id != params.excludeId
  );
});
