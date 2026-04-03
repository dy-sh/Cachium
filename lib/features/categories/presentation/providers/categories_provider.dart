import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/optimistic_notifier.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../transactions/presentation/providers/recurring_rules_provider.dart';
import '../../../transactions/presentation/providers/transaction_templates_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/category.dart';
import '../../data/models/category_tree_node.dart';

class CategoriesNotifier extends AsyncNotifier<List<Category>>
    with OptimisticAsyncNotifier<Category> {
  @override
  Future<List<Category>> build() async {
    final repo = ref.watch(categoryRepositoryProvider);
    return repo.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    await runOptimistic(
      update: (categories) => [...categories, category],
      action: () => ref.read(categoryRepositoryProvider).createCategory(category),
      onError: (e) => RepositoryException.create(entityType: 'Category', cause: e),
    );
  }

  Future<void> updateCategory(Category category) async {
    await runOptimistic(
      update: (categories) =>
          categories.map((c) => c.id == category.id ? category : c).toList(),
      action: () => ref.read(categoryRepositoryProvider).updateCategory(category),
      onError: (e) => RepositoryException.update(entityType: 'Category', entityId: category.id, cause: e),
    );
  }

  Future<void> deleteCategory(String id) async {
    // Safety guard: prevent orphaning transactions (must run before optimistic update)
    _assertNoCategoryTransactions({id});

    await runOptimistic(
      update: (categories) => categories.where((c) => c.id != id).toList(),
      action: () async {
        await ref.read(categoryRepositoryProvider).deleteCategory(id);
        await _cleanupReferencesForCategories({id});
      },
      onError: (e) => RepositoryException.delete(entityType: 'Category', entityId: id, cause: e),
    );
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
      // Safety guard: prevent orphaning transactions
      _assertNoCategoryTransactions(allIdsToRemove);

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

      // Clean up recurring rules and templates referencing deleted categories
      await _cleanupReferencesForCategories(allIdsToRemove);
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
      // Safety guard: prevent orphaning transactions (only check parent, children are promoted)
      _assertNoCategoryTransactions({id});
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

      // Clean up recurring rules and templates referencing deleted category
      await _cleanupReferencesForCategories({id});

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

  /// Merge source category into target category.
  /// Reassigns all transactions, moves subcategories, and soft-deletes source.
  Future<void> mergeCategory(String sourceId, String targetId) async {
    final previousState = state;
    final categories = state.valueOrNull;
    if (categories == null) return;

    try {
      final db = ref.read(databaseProvider);
      final repo = ref.read(categoryRepositoryProvider);

      await db.transaction(() async {
        // 1. Reassign all transactions from source to target
        await ref.read(transactionsProvider.notifier)
            .moveTransactionsToCategory(sourceId, targetId);

        // 2. Move source's subcategories under target
        final children = categories.where((c) => c.parentId == sourceId).toList();
        final targetChildren = categories
            .where((c) => c.parentId == targetId)
            .toList();
        var nextSortOrder = targetChildren.isEmpty
            ? 0
            : targetChildren.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

        for (final child in children) {
          final updated = child.copyWith(
            parentId: targetId,
            sortOrder: nextSortOrder++,
          );
          await repo.updateCategory(updated);
        }

        // 3. Soft-delete the source category
        await repo.deleteCategory(sourceId);
      });

      // Clean up references
      await _cleanupReferencesForCategories({sourceId});

      // Refresh state from database
      await refresh();
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Category', entityId: sourceId, cause: e),
        st,
      );
    }
  }

  /// Throws [ValidationException] if any active transactions reference the given category IDs.
  void _assertNoCategoryTransactions(Set<String> categoryIds) {
    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
    final hasReferences = transactions.any((t) => categoryIds.contains(t.categoryId));
    if (hasReferences) {
      throw const ValidationException(
        message: 'Cannot delete category with existing transactions. Reassign transactions first.',
        code: 'CATEGORY_HAS_TRANSACTIONS',
      );
    }
  }

  /// Clean up budgets, recurring rules, and templates that reference deleted category IDs.
  Future<void> _cleanupReferencesForCategories(Set<String> categoryIds) async {
    // Delete budgets referencing deleted categories
    final budgets = ref.read(budgetsProvider).valueOrNull ?? [];
    for (final budget in budgets) {
      if (categoryIds.contains(budget.categoryId)) {
        await ref.read(budgetsProvider.notifier).deleteBudget(budget.id);
      }
    }

    final rules = ref.read(recurringRulesProvider).valueOrNull ?? [];
    for (final rule in rules) {
      if (categoryIds.contains(rule.categoryId)) {
        await ref.read(recurringRulesProvider.notifier).deleteRule(rule.id);
      }
    }

    final templates = ref.read(transactionTemplatesProvider).valueOrNull ?? [];
    for (final template in templates) {
      if (template.categoryId != null && categoryIds.contains(template.categoryId)) {
        await ref.read(transactionTemplatesProvider.notifier).deleteTemplate(template.id);
      }
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

/// Computed map for O(1) category lookups. Rebuilt only when the category list changes.
final categoryMapProvider = Provider<Map<String, Category>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrNull;
  if (categories == null) return {};
  return {for (final c in categories) c.id: c};
});

final categoryByIdProvider = Provider.autoDispose.family<Category?, String>((ref, id) {
  return ref.watch(categoryMapProvider)[id];
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

/// Resolves whether assets should be shown for a given category.
/// Subcategories inherit from their root parent.
final categoryShowsAssetsProvider = Provider.family<bool, String?>((ref, categoryId) {
  if (categoryId == null) return false;
  final category = ref.watch(categoryByIdProvider(categoryId));
  if (category == null) return false;
  if (category.parentId == null) return category.showAssets;
  final parent = ref.watch(categoryByIdProvider(category.parentId!));
  return parent?.showAssets ?? false;
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

/// Returns category IDs sorted by most recent transaction usage for a specific type.
/// Categories without transactions appear last, sorted by sort order.
final recentlyUsedCategoryIdsProvider = Provider.family<List<String>, CategoryType>((ref, type) {
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.valueOrEmpty;

  final typeCategories = categories.where((c) => c.type == type).toList();
  if (typeCategories.isEmpty) return [];

  // Get most recent transaction date per category
  final Map<String, DateTime> lastUsedMap = {};
  if (transactions != null) {
    for (final tx in transactions) {
      // Only consider transactions that match the category type
      final category = categories.firstWhere(
        (c) => c.id == tx.categoryId,
        orElse: () => categories.first,
      );
      if (category.type != type) continue;

      final current = lastUsedMap[tx.categoryId];
      if (current == null || tx.createdAt.isAfter(current)) {
        lastUsedMap[tx.categoryId] = tx.createdAt;
      }
    }
  }

  // Sort categories: recently used first, then by sort order
  final sortedCategories = List<Category>.from(typeCategories);
  sortedCategories.sort((a, b) {
    final aLastUsed = lastUsedMap[a.id];
    final bLastUsed = lastUsedMap[b.id];

    // Both have transactions - sort by last used
    if (aLastUsed != null && bLastUsed != null) {
      return bLastUsed.compareTo(aLastUsed);
    }
    // Only a has transactions
    if (aLastUsed != null) return -1;
    // Only b has transactions
    if (bLastUsed != null) return 1;
    // Neither has transactions - sort by sort order
    return a.sortOrder.compareTo(b.sortOrder);
  });

  return sortedCategories.map((c) => c.id).toList();
});
