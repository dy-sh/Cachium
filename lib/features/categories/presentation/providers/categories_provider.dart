import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/models/category.dart';
import '../../data/models/category_tree_node.dart';

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repo = ref.watch(categoryRepositoryProvider);
    return repo.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    final previousState = state;

    try {
      final repo = ref.read(categoryRepositoryProvider);

      // Optimistically update local state
      state = state.whenData((categories) => [...categories, category]);

      // Save to encrypted database
      await repo.createCategory(category);
    } catch (e, st) {
      // Revert to previous state on error
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.create(entityType: 'Category', cause: e),
        st,
      );
    }
  }

  Future<void> updateCategory(Category category) async {
    final previousState = state;

    try {
      final repo = ref.read(categoryRepositoryProvider);

      // Optimistically update local state
      state = state.whenData(
        (categories) =>
            categories.map((c) => c.id == category.id ? category : c).toList(),
      );

      // Update in encrypted database
      await repo.updateCategory(category);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Category', entityId: category.id, cause: e),
        st,
      );
    }
  }

  Future<void> deleteCategory(String id) async {
    final previousState = state;

    try {
      final repo = ref.read(categoryRepositoryProvider);

      // Optimistically update local state
      state = state.whenData(
        (categories) => categories.where((c) => c.id != id).toList(),
      );

      // Soft delete in database
      await repo.deleteCategory(id);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'Category', entityId: id, cause: e),
        st,
      );
    }
  }

  Future<void> updateParent(String categoryId, String? newParentId) async {
    final categories = state.valueOrNull;
    if (categories == null) return;

    if (CategoryTreeBuilder.wouldCreateCycle(categories, categoryId, newParentId)) {
      return;
    }

    final category = categories.firstWhere((c) => c.id == categoryId);

    final siblingsInNewParent = categories
        .where((c) => c.parentId == newParentId && c.type == category.type)
        .toList();
    final newSortOrder = siblingsInNewParent.isEmpty
        ? 0
        : siblingsInNewParent.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    final updated = category.copyWith(
      parentId: newParentId,
      clearParentId: newParentId == null,
      sortOrder: newSortOrder,
    );
    await updateCategory(updated);
  }

  Future<void> reorderInParent(String categoryId, int newSortOrder) async {
    final categories = state.valueOrNull;
    if (categories == null) return;

    final category = categories.firstWhere((c) => c.id == categoryId);
    final updated = category.copyWith(sortOrder: newSortOrder);
    await updateCategory(updated);
  }

  /// Moves a category to a specific position among siblings.
  /// [targetParentId] - the parent under which to place the category (null for root)
  /// [insertBeforeCategoryId] - insert before this category, or null to insert at end
  Future<void> moveCategoryToPosition(String categoryId, String? targetParentId, String? insertBeforeCategoryId) async {
    final previousState = state;
    final categories = state.valueOrNull;
    if (categories == null) return;

    final category = categories.firstWhere((c) => c.id == categoryId);

    // Prevent moving to itself or creating cycles
    if (CategoryTreeBuilder.wouldCreateCycle(categories, categoryId, targetParentId)) {
      return;
    }

    try {
      // Get siblings in target parent (excluding the dragged item)
      final siblings = categories
          .where((c) => c.parentId == targetParentId && c.type == category.type && c.id != categoryId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final db = ref.read(databaseProvider);
      final repo = ref.read(categoryRepositoryProvider);

      // Wrap in transaction to prevent locking
      await db.transaction(() async {
        int newSortOrder;
        if (insertBeforeCategoryId == null) {
          // Insert at end
          newSortOrder = siblings.isEmpty ? 0 : siblings.last.sortOrder + 1;
        } else {
          // Find the target position
          final targetIndex = siblings.indexWhere((c) => c.id == insertBeforeCategoryId);
          if (targetIndex == -1) {
            newSortOrder = siblings.isEmpty ? 0 : siblings.last.sortOrder + 1;
          } else {
            newSortOrder = siblings[targetIndex].sortOrder;
            // Shift all items at and after target position
            for (int i = targetIndex; i < siblings.length; i++) {
              final sibling = siblings[i];
              await repo.updateCategory(sibling.copyWith(sortOrder: sibling.sortOrder + 1));
            }
          }
        }

        final updated = category.copyWith(
          parentId: targetParentId,
          clearParentId: targetParentId == null,
          sortOrder: newSortOrder,
        );
        await repo.updateCategory(updated);
      });

      // Refresh state from database
      await refresh();
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Category', entityId: categoryId, cause: e),
        st,
      );
    }
  }

  Future<void> promoteChildren(String parentId) async {
    final previousState = state;
    final categories = state.valueOrNull;
    if (categories == null) return;

    final parent = categories.firstWhere((c) => c.id == parentId);
    final children = categories.where((c) => c.parentId == parentId).toList();

    if (children.isEmpty) return;

    try {
      final rootSiblings = categories
          .where((c) => c.parentId == parent.parentId && c.type == parent.type)
          .toList();
      var nextSortOrder = rootSiblings.isEmpty
          ? 0
          : rootSiblings.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

      final db = ref.read(databaseProvider);
      final repo = ref.read(categoryRepositoryProvider);

      // Wrap in transaction to prevent locking
      await db.transaction(() async {
        for (final child in children) {
          final updated = child.copyWith(
            parentId: parent.parentId,
            clearParentId: parent.parentId == null,
            sortOrder: nextSortOrder++,
          );
          await repo.updateCategory(updated);
        }
      });

      // Refresh state from database
      await refresh();
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Category', entityId: parentId, cause: e),
        st,
      );
    }
  }

  Future<void> deleteWithChildren(String id) async {
    final previousState = state;
    final categories = state.valueOrNull;
    if (categories == null) return;

    final descendants = CategoryTreeBuilder.getDescendantIds(categories, id);
    final allIdsToRemove = {...descendants, id};

    try {
      final db = ref.read(databaseProvider);
      final repo = ref.read(categoryRepositoryProvider);

      // Optimistically update local state
      state = state.whenData(
        (cats) => cats.where((c) => !allIdsToRemove.contains(c.id)).toList(),
      );

      // Wrap in transaction to prevent locking
      await db.transaction(() async {
        for (final descendantId in descendants.reversed) {
          await repo.deleteCategory(descendantId);
        }
        await repo.deleteCategory(id);
      });
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'Category', entityId: id, cause: e),
        st,
      );
    }
  }

  Future<void> deleteCategoryPromotingChildren(String id) async {
    final previousState = state;
    final categories = state.valueOrNull;
    if (categories == null) return;

    final parent = categories.firstWhere((c) => c.id == id);
    final children = categories.where((c) => c.parentId == id).toList();

    try {
      final rootSiblings = categories
          .where((c) => c.parentId == parent.parentId && c.type == parent.type)
          .toList();
      var nextSortOrder = rootSiblings.isEmpty
          ? 0
          : rootSiblings.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

      final db = ref.read(databaseProvider);
      final repo = ref.read(categoryRepositoryProvider);

      // Wrap in transaction to prevent locking
      await db.transaction(() async {
        // Promote children first
        for (final child in children) {
          final updated = child.copyWith(
            parentId: parent.parentId,
            clearParentId: parent.parentId == null,
            sortOrder: nextSortOrder++,
          );
          await repo.updateCategory(updated);
        }

        // Then delete the parent
        await repo.deleteCategory(id);
      });

      // Refresh state from database
      await refresh();
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'Category', entityId: id, cause: e),
        st,
      );
    }
  }

  /// Refresh categories from database
  Future<void> refresh() async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      state = AsyncData(await repo.getAllCategories());
    } catch (e, st) {
      state = AsyncError(
        e is AppException ? e : RepositoryException.fetch(entityType: 'Category', cause: e),
        st,
      );
    }
  }
}

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  return categories.where((c) => c.type == CategoryType.income).toList();
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  return categories.where((c) => c.type == CategoryType.expense).toList();
});

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrNull;
  if (categories == null) return null;
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

final rootIncomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  return categories
      .where((c) => c.type == CategoryType.income && c.parentId == null)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final rootExpenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  return categories
      .where((c) => c.type == CategoryType.expense && c.parentId == null)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final childCategoriesProvider = Provider.family<List<Category>, String>((ref, parentId) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  return categories
      .where((c) => c.parentId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final hasChildrenProvider = Provider.family<bool, String>((ref, categoryId) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  return categories.any((c) => c.parentId == categoryId);
});

final categoryTreeProvider = Provider.family<List<CategoryTreeNode>, CategoryType>((ref, type) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  final filteredCategories = categories.where((c) => c.type == type).toList();
  return CategoryTreeBuilder.buildTree(filteredCategories);
});

final flatCategoryTreeProvider = Provider.family<List<CategoryTreeNode>, CategoryType>((ref, type) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  final filteredCategories = categories.where((c) => c.type == type).toList();
  return CategoryTreeBuilder.buildFlatTree(filteredCategories);
});

final categoryAncestorsProvider = Provider.family<List<Category>, String>((ref, categoryId) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  try {
    return CategoryTreeBuilder.getAncestors(categories, categoryId);
  } catch (_) {
    return [];
  }
});

/// Checks if a category name already exists (case-insensitive).
/// Returns true if duplicate exists, excluding the category with excludeId.
final categoryNameExistsProvider = Provider.family<bool, ({String name, String? excludeId})>((ref, params) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;
  final nameLower = params.name.trim().toLowerCase();
  return categories.any((c) =>
    c.name.toLowerCase() == nameLower && c.id != params.excludeId
  );
});
