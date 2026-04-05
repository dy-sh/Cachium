import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cachium/features/categories/data/models/category.dart';
import 'package:cachium/features/categories/data/models/category_tree_node.dart';

Category _cat(String id, {String? parentId, int sortOrder = 0, String? name}) {
  return Category(
    id: id,
    name: name ?? 'Cat $id',
    icon: Icons.star,
    colorIndex: 0,
    type: CategoryType.expense,
    parentId: parentId,
    sortOrder: sortOrder,
  );
}

void main() {
  group('CategoryTreeNode', () {
    test('hasChildren is true with children', () {
      final node = CategoryTreeNode(
        category: _cat('1'),
        children: [CategoryTreeNode(category: _cat('2'))],
      );
      expect(node.hasChildren, isTrue);
    });

    test('hasChildren is false without children', () {
      final node = CategoryTreeNode(category: _cat('1'));
      expect(node.hasChildren, isFalse);
    });

    test('isRoot is true when parentId is null', () {
      final node = CategoryTreeNode(category: _cat('1'));
      expect(node.isRoot, isTrue);
    });

    test('isRoot is false when parentId is set', () {
      final node = CategoryTreeNode(category: _cat('2', parentId: '1'));
      expect(node.isRoot, isFalse);
    });

    test('equality is based on category id', () {
      final n1 = CategoryTreeNode(category: _cat('1', name: 'A'));
      final n2 = CategoryTreeNode(category: _cat('1', name: 'B'));
      expect(n1, equals(n2));
    });
  });

  group('CategoryTreeBuilder.buildTree', () {
    test('returns empty list for empty input', () {
      final tree = CategoryTreeBuilder.buildTree([]);
      expect(tree, isEmpty);
    });

    test('builds flat list when no parents', () {
      final categories = [_cat('a', sortOrder: 1), _cat('b', sortOrder: 0)];
      final tree = CategoryTreeBuilder.buildTree(categories);
      expect(tree.length, 2);
      // Sorted by sortOrder: b (0), then a (1)
      expect(tree[0].category.id, 'b');
      expect(tree[1].category.id, 'a');
    });

    test('builds nested hierarchy', () {
      final categories = [
        _cat('root', sortOrder: 0),
        _cat('child1', parentId: 'root', sortOrder: 0),
        _cat('child2', parentId: 'root', sortOrder: 1),
      ];
      final tree = CategoryTreeBuilder.buildTree(categories);
      expect(tree.length, 1);
      expect(tree[0].category.id, 'root');
      expect(tree[0].children.length, 2);
      expect(tree[0].children[0].category.id, 'child1');
      expect(tree[0].children[1].category.id, 'child2');
    });

    test('sorts children by sortOrder', () {
      final categories = [
        _cat('root'),
        _cat('c', parentId: 'root', sortOrder: 2),
        _cat('a', parentId: 'root', sortOrder: 0),
        _cat('b', parentId: 'root', sortOrder: 1),
      ];
      final tree = CategoryTreeBuilder.buildTree(categories);
      final children = tree[0].children;
      expect(children[0].category.id, 'a');
      expect(children[1].category.id, 'b');
      expect(children[2].category.id, 'c');
    });

    test('assigns correct depth', () {
      final categories = [
        _cat('root'),
        _cat('child', parentId: 'root'),
        _cat('grandchild', parentId: 'child'),
      ];
      final tree = CategoryTreeBuilder.buildTree(categories);
      expect(tree[0].depth, 0);
      expect(tree[0].children[0].depth, 1);
      expect(tree[0].children[0].children[0].depth, 2);
    });
  });

  group('CategoryTreeBuilder.buildFlatTree', () {
    test('flattens in depth-first order', () {
      final categories = [
        _cat('root', sortOrder: 0),
        _cat('child1', parentId: 'root', sortOrder: 0),
        _cat('grandchild', parentId: 'child1', sortOrder: 0),
        _cat('child2', parentId: 'root', sortOrder: 1),
      ];
      final flat = CategoryTreeBuilder.buildFlatTree(categories);
      expect(flat.map((n) => n.category.id).toList(), [
        'root',
        'child1',
        'grandchild',
        'child2',
      ]);
    });

    test('returns empty list for empty input', () {
      expect(CategoryTreeBuilder.buildFlatTree([]), isEmpty);
    });
  });

  group('CategoryTreeBuilder.getAncestors', () {
    final categories = [
      _cat('root'),
      _cat('child', parentId: 'root'),
      _cat('grandchild', parentId: 'child'),
    ];

    test('root category has no ancestors', () {
      final ancestors = CategoryTreeBuilder.getAncestors(categories, 'root');
      expect(ancestors, isEmpty);
    });

    test('child returns parent as ancestor', () {
      final ancestors = CategoryTreeBuilder.getAncestors(categories, 'child');
      expect(ancestors.length, 1);
      expect(ancestors[0].id, 'root');
    });

    test('grandchild returns grandparent and parent', () {
      final ancestors = CategoryTreeBuilder.getAncestors(
        categories,
        'grandchild',
      );
      expect(ancestors.length, 2);
      expect(ancestors[0].id, 'root');
      expect(ancestors[1].id, 'child');
    });
  });

  group('CategoryTreeBuilder.getDescendantIds', () {
    final categories = [
      _cat('root'),
      _cat('child1', parentId: 'root'),
      _cat('child2', parentId: 'root'),
      _cat('grandchild', parentId: 'child1'),
    ];

    test('leaf node has no descendants', () {
      final ids = CategoryTreeBuilder.getDescendantIds(
        categories,
        'grandchild',
      );
      expect(ids, isEmpty);
    });

    test('parent returns all children', () {
      final ids = CategoryTreeBuilder.getDescendantIds(categories, 'root');
      expect(ids, containsAll(['child1', 'child2', 'grandchild']));
    });

    test('mid-level returns its subtree', () {
      final ids = CategoryTreeBuilder.getDescendantIds(categories, 'child1');
      expect(ids, ['grandchild']);
    });
  });

  group('CategoryTreeBuilder.wouldCreateCycle', () {
    final categories = [
      _cat('root'),
      _cat('child', parentId: 'root'),
      _cat('grandchild', parentId: 'child'),
      _cat('unrelated'),
    ];

    test('null parent never creates cycle', () {
      expect(
        CategoryTreeBuilder.wouldCreateCycle(categories, 'root', null),
        isFalse,
      );
    });

    test('self-reference creates cycle', () {
      expect(
        CategoryTreeBuilder.wouldCreateCycle(categories, 'root', 'root'),
        isTrue,
      );
    });

    test('descendant as parent creates cycle', () {
      expect(
        CategoryTreeBuilder.wouldCreateCycle(categories, 'root', 'grandchild'),
        isTrue,
      );
    });

    test('child as parent of root creates cycle', () {
      expect(
        CategoryTreeBuilder.wouldCreateCycle(categories, 'root', 'child'),
        isTrue,
      );
    });

    test('unrelated category as parent does not create cycle', () {
      expect(
        CategoryTreeBuilder.wouldCreateCycle(categories, 'root', 'unrelated'),
        isFalse,
      );
    });

    test('parent as new parent of child does not create cycle', () {
      expect(
        CategoryTreeBuilder.wouldCreateCycle(categories, 'grandchild', 'root'),
        isFalse,
      );
    });
  });
}
