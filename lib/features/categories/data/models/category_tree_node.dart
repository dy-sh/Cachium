import 'category.dart';

class CategoryTreeNode {
  final Category category;
  final List<CategoryTreeNode> children;
  final int depth;

  const CategoryTreeNode({
    required this.category,
    this.children = const [],
    this.depth = 0,
  });

  bool get hasChildren => children.isNotEmpty;

  bool get isRoot => category.parentId == null;

  CategoryTreeNode copyWith({
    Category? category,
    List<CategoryTreeNode>? children,
    int? depth,
  }) {
    return CategoryTreeNode(
      category: category ?? this.category,
      children: children ?? this.children,
      depth: depth ?? this.depth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryTreeNode && other.category.id == category.id;
  }

  @override
  int get hashCode => category.id.hashCode;
}

class CategoryTreeBuilder {
  static List<CategoryTreeNode> buildTree(
    List<Category> categories, {
    String? parentId,
    int depth = 0,
  }) {
    final children = categories
        .where((c) => c.parentId == parentId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return children.map((category) {
      final childNodes = buildTree(
        categories,
        parentId: category.id,
        depth: depth + 1,
      );
      return CategoryTreeNode(
        category: category,
        children: childNodes,
        depth: depth,
      );
    }).toList();
  }

  static List<CategoryTreeNode> buildFlatTree(List<Category> categories) {
    final result = <CategoryTreeNode>[];

    void addWithChildren(CategoryTreeNode node) {
      result.add(node);
      for (final child in node.children) {
        addWithChildren(child);
      }
    }

    final rootNodes = buildTree(categories);
    for (final node in rootNodes) {
      addWithChildren(node);
    }

    return result;
  }

  static List<Category> getAncestors(
    List<Category> categories,
    String categoryId,
  ) {
    final ancestors = <Category>[];
    String? currentId = categoryId;

    while (currentId != null) {
      final category = categories.firstWhere(
        (c) => c.id == currentId,
        orElse: () => throw StateError('Category not found: $currentId'),
      );
      if (category.parentId != null) {
        final parent = categories.firstWhere(
          (c) => c.id == category.parentId,
          orElse: () => throw StateError('Parent not found: ${category.parentId}'),
        );
        ancestors.insert(0, parent);
        currentId = parent.id;
        if (parent.parentId == null) break;
      } else {
        break;
      }
    }

    return ancestors;
  }

  static List<String> getDescendantIds(
    List<Category> categories,
    String categoryId,
  ) {
    final descendants = <String>[];

    void addDescendants(String parentId) {
      final children = categories.where((c) => c.parentId == parentId);
      for (final child in children) {
        descendants.add(child.id);
        addDescendants(child.id);
      }
    }

    addDescendants(categoryId);
    return descendants;
  }

  static bool wouldCreateCycle(
    List<Category> categories,
    String categoryId,
    String? newParentId,
  ) {
    if (newParentId == null) return false;
    if (categoryId == newParentId) return true;

    final descendants = getDescendantIds(categories, categoryId);
    return descendants.contains(newParentId);
  }
}
