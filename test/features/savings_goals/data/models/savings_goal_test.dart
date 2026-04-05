import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/savings_goals/data/models/savings_goal.dart';
import 'package:cachium/core/exceptions/app_exception.dart';

SavingsGoal _makeGoal({
  String id = 'goal-1',
  String name = 'Test Goal',
  double targetAmount = 1000.0,
  double currentAmount = 0.0,
  int colorIndex = 0,
  String? linkedAccountId,
  DateTime? targetDate,
  String? note,
  DateTime? createdAt,
}) {
  return SavingsGoal(
    id: id,
    name: name,
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    colorIndex: colorIndex,
    linkedAccountId: linkedAccountId,
    targetDate: targetDate,
    note: note,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('SavingsGoal.validate()', () {
    test('accepts valid goal', () {
      expect(() => _makeGoal().validate(), returnsNormally);
    });

    test('rejects empty id', () {
      expect(
        () => _makeGoal(id: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name', () {
      expect(
        () => _makeGoal(name: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative targetAmount', () {
      expect(
        () => _makeGoal(targetAmount: -1.0).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative currentAmount', () {
      expect(
        () => _makeGoal(currentAmount: -1.0).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative colorIndex', () {
      expect(
        () => _makeGoal(colorIndex: -1).validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts zero amounts', () {
      expect(
        () => _makeGoal(targetAmount: 0.0, currentAmount: 0.0).validate(),
        returnsNormally,
      );
    });
  });

  group('SavingsGoal.progressPercent', () {
    test('calculates percentage correctly', () {
      final goal = _makeGoal(targetAmount: 1000.0, currentAmount: 250.0);
      expect(goal.progressPercent, 25.0);
    });

    test('returns 0 when target is 0', () {
      final goal = _makeGoal(targetAmount: 0.0, currentAmount: 100.0);
      expect(goal.progressPercent, 0.0);
    });

    test('clamps at 100 when over target', () {
      final goal = _makeGoal(targetAmount: 100.0, currentAmount: 200.0);
      expect(goal.progressPercent, 100.0);
    });

    test('returns 0 when current is 0', () {
      final goal = _makeGoal(targetAmount: 1000.0, currentAmount: 0.0);
      expect(goal.progressPercent, 0.0);
    });

    test('returns 100 when exactly at target', () {
      final goal = _makeGoal(targetAmount: 500.0, currentAmount: 500.0);
      expect(goal.progressPercent, 100.0);
    });
  });

  group('SavingsGoal.remainingAmount', () {
    test('calculates remaining correctly', () {
      final goal = _makeGoal(targetAmount: 1000.0, currentAmount: 300.0);
      expect(goal.remainingAmount, 700.0);
    });

    test('clamps at 0 when over target', () {
      final goal = _makeGoal(targetAmount: 100.0, currentAmount: 200.0);
      expect(goal.remainingAmount, 0.0);
    });

    test('returns full target when current is 0', () {
      final goal = _makeGoal(targetAmount: 500.0, currentAmount: 0.0);
      expect(goal.remainingAmount, 500.0);
    });
  });

  group('SavingsGoal.isCompleted', () {
    test('false when below target', () {
      final goal = _makeGoal(targetAmount: 1000.0, currentAmount: 999.0);
      expect(goal.isCompleted, isFalse);
    });

    test('true when at target', () {
      final goal = _makeGoal(targetAmount: 1000.0, currentAmount: 1000.0);
      expect(goal.isCompleted, isTrue);
    });

    test('true when above target', () {
      final goal = _makeGoal(targetAmount: 1000.0, currentAmount: 1500.0);
      expect(goal.isCompleted, isTrue);
    });
  });

  group('SavingsGoal equality', () {
    test('goals with same id are equal', () {
      final g1 = _makeGoal(id: 'abc', name: 'A');
      final g2 = _makeGoal(id: 'abc', name: 'B');
      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
    });

    test('goals with different ids are not equal', () {
      final g1 = _makeGoal(id: 'abc');
      final g2 = _makeGoal(id: 'def');
      expect(g1, isNot(equals(g2)));
    });
  });

  group('SavingsGoal.copyWith()', () {
    test('updates specified fields', () {
      final goal = _makeGoal(name: 'Old', targetAmount: 100.0);
      final copy = goal.copyWith(name: 'New', targetAmount: 500.0);
      expect(copy.name, 'New');
      expect(copy.targetAmount, 500.0);
      expect(copy.id, goal.id);
    });

    test('clearLinkedAccountId sets to null', () {
      final goal = _makeGoal(linkedAccountId: 'acc-1');
      final copy = goal.copyWith(clearLinkedAccountId: true);
      expect(copy.linkedAccountId, isNull);
    });

    test('clearTargetDate sets to null', () {
      final goal = _makeGoal(targetDate: DateTime(2027, 1, 1));
      final copy = goal.copyWith(clearTargetDate: true);
      expect(copy.targetDate, isNull);
    });

    test('clearNote sets to null', () {
      final goal = _makeGoal(note: 'Some note');
      final copy = goal.copyWith(clearNote: true);
      expect(copy.note, isNull);
    });
  });
}
