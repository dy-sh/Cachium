import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cachium/features/tags/data/models/tag.dart';
import 'package:cachium/core/exceptions/app_exception.dart';

Tag _makeTag({
  String id = 'tag-1',
  String name = 'Test Tag',
  int colorIndex = 0,
  IconData icon = Icons.label,
  int sortOrder = 0,
}) {
  return Tag(
    id: id,
    name: name,
    colorIndex: colorIndex,
    icon: icon,
    sortOrder: sortOrder,
  );
}

void main() {
  group('Tag.validate()', () {
    test('accepts valid tag', () {
      expect(() => _makeTag().validate(), returnsNormally);
    });

    test('rejects empty id', () {
      expect(
        () => _makeTag(id: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name', () {
      expect(
        () => _makeTag(name: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative colorIndex', () {
      expect(
        () => _makeTag(colorIndex: -1).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative sortOrder', () {
      expect(
        () => _makeTag(sortOrder: -1).validate(),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Tag equality', () {
    test('tags with same id are equal', () {
      final t1 = _makeTag(id: 'abc', name: 'A');
      final t2 = _makeTag(id: 'abc', name: 'B');
      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
    });

    test('tags with different ids are not equal', () {
      final t1 = _makeTag(id: 'abc');
      final t2 = _makeTag(id: 'def');
      expect(t1, isNot(equals(t2)));
    });
  });

  group('Tag.copyWith()', () {
    test('updates specified fields', () {
      final tag = _makeTag(name: 'Old', sortOrder: 0);
      final copy = tag.copyWith(name: 'New', sortOrder: 5);
      expect(copy.name, 'New');
      expect(copy.sortOrder, 5);
      expect(copy.id, tag.id);
    });

    test('preserves unmodified fields', () {
      final tag = _makeTag(name: 'Test', colorIndex: 3);
      final copy = tag.copyWith(sortOrder: 10);
      expect(copy.name, 'Test');
      expect(copy.colorIndex, 3);
    });
  });
}
