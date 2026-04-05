import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/transactions/data/models/recurring_rule.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';

RecurringRule _makeRule({
  String id = 'rule-1',
  String name = 'Test Rule',
  double amount = 50.0,
  TransactionType type = TransactionType.expense,
  String categoryId = 'cat-1',
  String accountId = 'acc-1',
  String? destinationAccountId,
  String? merchant,
  String? note,
  String currencyCode = 'USD',
  double? destinationAmount,
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  DateTime? startDate,
  DateTime? endDate,
  DateTime? lastGeneratedDate,
  bool isActive = true,
  DateTime? createdAt,
}) {
  return RecurringRule(
    id: id,
    name: name,
    amount: amount,
    type: type,
    categoryId: categoryId,
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    merchant: merchant,
    note: note,
    currencyCode: currencyCode,
    destinationAmount: destinationAmount,
    frequency: frequency,
    startDate: startDate ?? DateTime(2026, 1, 1),
    endDate: endDate,
    lastGeneratedDate: lastGeneratedDate ?? DateTime(2026, 1, 1),
    isActive: isActive,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('RecurrenceFrequency.displayName', () {
    test('returns correct display names', () {
      expect(RecurrenceFrequency.daily.displayName, 'Daily');
      expect(RecurrenceFrequency.weekly.displayName, 'Weekly');
      expect(RecurrenceFrequency.biweekly.displayName, 'Bi-weekly');
      expect(RecurrenceFrequency.monthly.displayName, 'Monthly');
      expect(RecurrenceFrequency.yearly.displayName, 'Yearly');
    });
  });

  group('RecurrenceFrequency.nextDate', () {
    test('daily adds 1 day', () {
      final date = DateTime(2026, 3, 15);
      expect(RecurrenceFrequency.daily.nextDate(date), DateTime(2026, 3, 16));
    });

    test('weekly adds 7 days', () {
      final date = DateTime(2026, 3, 1);
      expect(RecurrenceFrequency.weekly.nextDate(date), DateTime(2026, 3, 8));
    });

    test('biweekly adds 14 days', () {
      final date = DateTime(2026, 3, 1);
      expect(
        RecurrenceFrequency.biweekly.nextDate(date),
        DateTime(2026, 3, 15),
      );
    });

    test('monthly adds 1 month', () {
      final date = DateTime(2026, 3, 15);
      expect(
        RecurrenceFrequency.monthly.nextDate(date),
        DateTime(2026, 4, 15),
      );
    });

    test('monthly December rolls to January', () {
      final date = DateTime(2026, 12, 15);
      expect(
        RecurrenceFrequency.monthly.nextDate(date),
        DateTime(2027, 1, 15),
      );
    });

    test('monthly handles month-end overflow (Jan 31 rolls forward)', () {
      // Dart's DateTime(2026, 2, 31) normalizes to March 3
      final date = DateTime(2026, 1, 31);
      final next = RecurrenceFrequency.monthly.nextDate(date);
      // DateTime(2026, 2, 31) → March 3, 2026 (Feb has 28 days)
      expect(next, DateTime(2026, 2, 31));
    });

    test('yearly adds 1 year', () {
      final date = DateTime(2026, 6, 15);
      expect(
        RecurrenceFrequency.yearly.nextDate(date),
        DateTime(2027, 6, 15),
      );
    });

    test('yearly from leap day', () {
      // Feb 29, 2024 + 1 year → Dart's DateTime(2025, 2, 29) → March 1, 2025
      final date = DateTime(2024, 2, 29);
      final next = RecurrenceFrequency.yearly.nextDate(date);
      expect(next, DateTime(2025, 2, 29));
    });

    test('daily across month boundary', () {
      final date = DateTime(2026, 3, 31);
      expect(RecurrenceFrequency.daily.nextDate(date), DateTime(2026, 4, 1));
    });

    test('weekly across month boundary', () {
      final date = DateTime(2026, 3, 28);
      expect(RecurrenceFrequency.weekly.nextDate(date), DateTime(2026, 4, 4));
    });
  });

  group('RecurringRule equality', () {
    test('rules with same id are equal', () {
      final r1 = _makeRule(id: 'abc', name: 'A');
      final r2 = _makeRule(id: 'abc', name: 'B');
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });

    test('rules with different ids are not equal', () {
      final r1 = _makeRule(id: 'abc');
      final r2 = _makeRule(id: 'def');
      expect(r1, isNot(equals(r2)));
    });
  });

  group('RecurringRule.copyWith()', () {
    test('updates specified fields', () {
      final rule = _makeRule(name: 'Old', amount: 10.0);
      final copy = rule.copyWith(name: 'New', amount: 20.0);
      expect(copy.name, 'New');
      expect(copy.amount, 20.0);
      expect(copy.id, rule.id);
    });

    test('clearDestinationAccountId sets to null', () {
      final rule = _makeRule(destinationAccountId: 'acc-2');
      final copy = rule.copyWith(clearDestinationAccountId: true);
      expect(copy.destinationAccountId, isNull);
    });

    test('clearDestinationAmount sets to null', () {
      final rule = _makeRule(destinationAmount: 100.0);
      final copy = rule.copyWith(clearDestinationAmount: true);
      expect(copy.destinationAmount, isNull);
    });

    test('clearEndDate sets to null', () {
      final rule = _makeRule(endDate: DateTime(2027, 1, 1));
      final copy = rule.copyWith(clearEndDate: true);
      expect(copy.endDate, isNull);
    });
  });

  group('RecurringRule.nextDueDate', () {
    test('returns null when inactive', () {
      final rule = _makeRule(isActive: false);
      expect(rule.nextDueDate, isNull);
    });

    test('returns next date when active with no end date', () {
      final rule = _makeRule(
        lastGeneratedDate: DateTime(2026, 3, 1),
        frequency: RecurrenceFrequency.monthly,
      );
      expect(rule.nextDueDate, DateTime(2026, 4, 1));
    });

    test('returns null when next date is past end date', () {
      final rule = _makeRule(
        lastGeneratedDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 15),
        frequency: RecurrenceFrequency.monthly,
      );
      // Next would be Jan 1, 2027, which is after Dec 15, 2026
      expect(rule.nextDueDate, isNull);
    });

    test('returns next date when before end date', () {
      final rule = _makeRule(
        lastGeneratedDate: DateTime(2026, 3, 1),
        endDate: DateTime(2027, 1, 1),
        frequency: RecurrenceFrequency.monthly,
      );
      expect(rule.nextDueDate, DateTime(2026, 4, 1));
    });
  });
}
