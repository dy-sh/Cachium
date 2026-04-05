import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/transactions/presentation/providers/transaction_form_change_detector.dart';

void main() {
  group('isSameDateTime', () {
    test('same date and time returns true', () {
      final a = DateTime(2026, 3, 15, 10, 30);
      final b = DateTime(2026, 3, 15, 10, 30);
      expect(isSameDateTime(a, b), isTrue);
    });

    test('ignores seconds', () {
      final a = DateTime(2026, 3, 15, 10, 30, 0);
      final b = DateTime(2026, 3, 15, 10, 30, 45);
      expect(isSameDateTime(a, b), isTrue);
    });

    test('ignores milliseconds', () {
      final a = DateTime(2026, 3, 15, 10, 30, 0, 0);
      final b = DateTime(2026, 3, 15, 10, 30, 0, 999);
      expect(isSameDateTime(a, b), isTrue);
    });

    test('different minute returns false', () {
      final a = DateTime(2026, 3, 15, 10, 30);
      final b = DateTime(2026, 3, 15, 10, 31);
      expect(isSameDateTime(a, b), isFalse);
    });

    test('different hour returns false', () {
      final a = DateTime(2026, 3, 15, 10, 30);
      final b = DateTime(2026, 3, 15, 11, 30);
      expect(isSameDateTime(a, b), isFalse);
    });

    test('different day returns false', () {
      final a = DateTime(2026, 3, 15, 10, 30);
      final b = DateTime(2026, 3, 16, 10, 30);
      expect(isSameDateTime(a, b), isFalse);
    });

    test('different month returns false', () {
      final a = DateTime(2026, 3, 15, 10, 30);
      final b = DateTime(2026, 4, 15, 10, 30);
      expect(isSameDateTime(a, b), isFalse);
    });

    test('different year returns false', () {
      final a = DateTime(2026, 3, 15, 10, 30);
      final b = DateTime(2027, 3, 15, 10, 30);
      expect(isSameDateTime(a, b), isFalse);
    });

    test('null b returns false', () {
      final a = DateTime(2026, 3, 15);
      expect(isSameDateTime(a, null), isFalse);
    });
  });

  group('sameTagIds', () {
    test('same tags in same order returns true', () {
      expect(sameTagIds(['a', 'b', 'c'], ['a', 'b', 'c']), isTrue);
    });

    test('same tags in different order returns true', () {
      expect(sameTagIds(['c', 'a', 'b'], ['a', 'b', 'c']), isTrue);
    });

    test('different lengths returns false', () {
      expect(sameTagIds(['a', 'b'], ['a', 'b', 'c']), isFalse);
    });

    test('different tags returns false', () {
      expect(sameTagIds(['a', 'b'], ['a', 'c']), isFalse);
    });

    test('both empty returns true', () {
      expect(sameTagIds([], []), isTrue);
    });

    test('one empty one not returns false', () {
      expect(sameTagIds([], ['a']), isFalse);
    });
  });
}
