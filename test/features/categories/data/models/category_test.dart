import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cachium/features/categories/data/models/category.dart';
import 'package:cachium/core/exceptions/app_exception.dart';

Category _makeCategory({
  String id = 'cat-1',
  String name = 'Test Category',
  IconData icon = Icons.star,
  int colorIndex = 0,
  CategoryType type = CategoryType.expense,
  bool isCustom = false,
  String? parentId,
  int sortOrder = 0,
  bool showAssets = false,
}) {
  return Category(
    id: id,
    name: name,
    icon: icon,
    colorIndex: colorIndex,
    type: type,
    isCustom: isCustom,
    parentId: parentId,
    sortOrder: sortOrder,
    showAssets: showAssets,
  );
}

void main() {
  group('Category.validate()', () {
    test('accepts valid category', () {
      expect(() => _makeCategory().validate(), returnsNormally);
    });

    test('rejects empty id', () {
      expect(
        () => _makeCategory(id: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name', () {
      expect(
        () => _makeCategory(name: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative colorIndex', () {
      expect(
        () => _makeCategory(colorIndex: -1).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative sortOrder', () {
      expect(
        () => _makeCategory(sortOrder: -1).validate(),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Category equality', () {
    test('categories with same id are equal', () {
      final c1 = _makeCategory(id: 'abc', name: 'A');
      final c2 = _makeCategory(id: 'abc', name: 'B');
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('categories with different ids are not equal', () {
      final c1 = _makeCategory(id: 'abc');
      final c2 = _makeCategory(id: 'def');
      expect(c1, isNot(equals(c2)));
    });
  });

  group('Category.copyWith()', () {
    test('updates specified fields', () {
      final cat = _makeCategory(name: 'Old', sortOrder: 0);
      final copy = cat.copyWith(name: 'New', sortOrder: 5);
      expect(copy.name, 'New');
      expect(copy.sortOrder, 5);
      expect(copy.id, cat.id);
    });

    test('clearParentId sets parentId to null', () {
      final cat = _makeCategory(parentId: 'parent-1');
      final copy = cat.copyWith(clearParentId: true);
      expect(copy.parentId, isNull);
    });

    test('preserves parentId when not cleared', () {
      final cat = _makeCategory(parentId: 'parent-1');
      final copy = cat.copyWith(name: 'New');
      expect(copy.parentId, 'parent-1');
    });
  });
}
