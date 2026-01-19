import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/crud_notifier.dart';
import '../../data/models/category.dart';
import '../../data/models/category_tree_node.dart';

class CategoriesNotifier extends CrudNotifier<Category> {
  @override
  String getId(Category item) => item.id;

  @override
  List<Category> build() {
    return List.from(DefaultCategories.all);
  }

  void addCategory(Category category) => add(category);

  void updateCategory(Category category) => update(category);

  void deleteCategory(String id) => delete(id);

  void updateParent(String categoryId, String? newParentId) {
    final categories = state;

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
    update(updated);
  }

  void reorderInParent(String categoryId, int newSortOrder) {
    final category = state.firstWhere((c) => c.id == categoryId);
    final updated = category.copyWith(sortOrder: newSortOrder);
    update(updated);
  }

  void promoteChildren(String parentId) {
    final parent = state.firstWhere((c) => c.id == parentId);
    final children = state.where((c) => c.parentId == parentId).toList();

    final rootSiblings = state
        .where((c) => c.parentId == parent.parentId && c.type == parent.type)
        .toList();
    var nextSortOrder = rootSiblings.isEmpty
        ? 0
        : rootSiblings.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    for (final child in children) {
      final updated = child.copyWith(
        parentId: parent.parentId,
        clearParentId: parent.parentId == null,
        sortOrder: nextSortOrder++,
      );
      update(updated);
    }
  }

  void deleteWithChildren(String id) {
    final descendants = CategoryTreeBuilder.getDescendantIds(state, id);

    for (final descendantId in descendants.reversed) {
      delete(descendantId);
    }
    delete(id);
  }

  void deleteCategoryPromotingChildren(String id) {
    promoteChildren(id);
    delete(id);
  }
}

final categoriesProvider = NotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((c) => c.type == CategoryType.income).toList();
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((c) => c.type == CategoryType.expense).toList();
});

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider);
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

final rootIncomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories
      .where((c) => c.type == CategoryType.income && c.parentId == null)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final rootExpenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories
      .where((c) => c.type == CategoryType.expense && c.parentId == null)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final childCategoriesProvider = Provider.family<List<Category>, String>((ref, parentId) {
  final categories = ref.watch(categoriesProvider);
  return categories
      .where((c) => c.parentId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final hasChildrenProvider = Provider.family<bool, String>((ref, categoryId) {
  final categories = ref.watch(categoriesProvider);
  return categories.any((c) => c.parentId == categoryId);
});

final categoryTreeProvider = Provider.family<List<CategoryTreeNode>, CategoryType>((ref, type) {
  final categories = ref.watch(categoriesProvider);
  final filteredCategories = categories.where((c) => c.type == type).toList();
  return CategoryTreeBuilder.buildTree(filteredCategories);
});

final flatCategoryTreeProvider = Provider.family<List<CategoryTreeNode>, CategoryType>((ref, type) {
  final categories = ref.watch(categoriesProvider);
  final filteredCategories = categories.where((c) => c.type == type).toList();
  return CategoryTreeBuilder.buildFlatTree(filteredCategories);
});

final categoryAncestorsProvider = Provider.family<List<Category>, String>((ref, categoryId) {
  final categories = ref.watch(categoriesProvider);
  try {
    return CategoryTreeBuilder.getAncestors(categories, categoryId);
  } catch (_) {
    return [];
  }
});

/// Checks if a category name already exists (case-insensitive).
/// Returns true if duplicate exists, excluding the category with excludeId.
final categoryNameExistsProvider = Provider.family<bool, ({String name, String? excludeId})>((ref, params) {
  final categories = ref.watch(categoriesProvider);
  final nameLower = params.name.trim().toLowerCase();
  return categories.any((c) =>
    c.name.toLowerCase() == nameLower && c.id != params.excludeId
  );
});
