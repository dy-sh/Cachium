import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/recurring_transaction.dart';

RecurringTransaction _makeRecurring({
  double amount = 100,
  RecurringFrequency frequency = RecurringFrequency.monthly,
}) {
  return RecurringTransaction(
    id: 'rt-1',
    categoryId: 'cat-1',
    amount: amount,
    frequency: frequency,
    confidence: RecurringConfidence.high,
    lastOccurrence: DateTime(2026, 3, 1),
    matchingTransactions: const [],
    occurrenceCount: 3,
  );
}

void main() {
  group('RecurringFrequency extensions', () {
    test('displayName returns correct values', () {
      expect(RecurringFrequency.weekly.displayName, 'Weekly');
      expect(RecurringFrequency.biweekly.displayName, 'Bi-weekly');
      expect(RecurringFrequency.monthly.displayName, 'Monthly');
      expect(RecurringFrequency.yearly.displayName, 'Yearly');
    });

    test('averageDays returns correct values', () {
      expect(RecurringFrequency.weekly.averageDays, 7);
      expect(RecurringFrequency.biweekly.averageDays, 14);
      expect(RecurringFrequency.monthly.averageDays, 30);
      expect(RecurringFrequency.yearly.averageDays, 365);
    });
  });

  group('RecurringConfidence extensions', () {
    test('displayName returns correct values', () {
      expect(RecurringConfidence.high.displayName, 'High');
      expect(RecurringConfidence.medium.displayName, 'Medium');
      expect(RecurringConfidence.low.displayName, 'Low');
    });
  });

  group('RecurringTransaction.monthlyAmount', () {
    test('weekly: amount * 4.33', () {
      final rt = _makeRecurring(amount: 100, frequency: RecurringFrequency.weekly);
      expect(rt.monthlyAmount, closeTo(433, 0.01));
    });

    test('biweekly: amount * 2.17', () {
      final rt = _makeRecurring(amount: 100, frequency: RecurringFrequency.biweekly);
      expect(rt.monthlyAmount, closeTo(217, 0.01));
    });

    test('monthly: amount unchanged', () {
      final rt = _makeRecurring(amount: 100, frequency: RecurringFrequency.monthly);
      expect(rt.monthlyAmount, 100);
    });

    test('yearly: amount / 12', () {
      final rt = _makeRecurring(amount: 1200, frequency: RecurringFrequency.yearly);
      expect(rt.monthlyAmount, 100);
    });
  });

  group('RecurringTransaction.yearlyAmount', () {
    test('weekly: amount * 52', () {
      final rt = _makeRecurring(amount: 10, frequency: RecurringFrequency.weekly);
      expect(rt.yearlyAmount, 520);
    });

    test('biweekly: amount * 26', () {
      final rt = _makeRecurring(amount: 10, frequency: RecurringFrequency.biweekly);
      expect(rt.yearlyAmount, 260);
    });

    test('monthly: amount * 12', () {
      final rt = _makeRecurring(amount: 100, frequency: RecurringFrequency.monthly);
      expect(rt.yearlyAmount, 1200);
    });

    test('yearly: amount unchanged', () {
      final rt = _makeRecurring(amount: 5000, frequency: RecurringFrequency.yearly);
      expect(rt.yearlyAmount, 5000);
    });
  });

  group('RecurringSummary.empty', () {
    test('creates empty summary', () {
      final s = RecurringSummary.empty();
      expect(s.subscriptions, isEmpty);
      expect(s.totalMonthly, 0);
      expect(s.totalYearly, 0);
      expect(s.count, 0);
    });
  });
}
