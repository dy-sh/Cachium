import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/budgets/data/models/budget.dart';

Budget _makeBudget({
  String id = 'bgt-1',
  String categoryId = 'cat-1',
  double amount = 500.0,
  int year = 2024,
  int month = 6,
}) {
  return Budget(
    id: id,
    categoryId: categoryId,
    amount: amount,
    year: year,
    month: month,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('Budget validation', () {
    test('accepts valid budget', () {
      expect(() => _makeBudget(), returnsNormally);
    });

    test('rejects negative amount', () {
      expect(
        () => _makeBudget(amount: -1.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts zero amount', () {
      expect(() => _makeBudget(amount: 0.0), returnsNormally);
    });

    test('rejects month below 1', () {
      expect(
        () => _makeBudget(month: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects month above 12', () {
      expect(
        () => _makeBudget(month: 13),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts valid month range', () {
      for (var m = 1; m <= 12; m++) {
        expect(() => _makeBudget(month: m), returnsNormally);
      }
    });

    test('rejects year below 2000', () {
      expect(
        () => _makeBudget(year: 1999),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects year above 2100', () {
      expect(
        () => _makeBudget(year: 2101),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Budget equality', () {
    test('budgets with same id are equal', () {
      final b1 = _makeBudget(id: 'abc', amount: 100.0);
      final b2 = _makeBudget(id: 'abc', amount: 200.0);
      expect(b1, equals(b2));
    });

    test('budgets with different ids are not equal', () {
      final b1 = _makeBudget(id: 'abc');
      final b2 = _makeBudget(id: 'def');
      expect(b1, isNot(equals(b2)));
    });
  });

  group('Budget copyWith', () {
    test('creates copy with updated fields', () {
      final b = _makeBudget(amount: 500.0);
      final copy = b.copyWith(amount: 1000.0);
      expect(copy.amount, 1000.0);
      expect(copy.id, b.id);
    });
  });
}
