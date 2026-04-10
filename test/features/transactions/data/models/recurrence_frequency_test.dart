import 'package:cachium/features/transactions/data/models/recurring_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurrenceFrequency.nextDate', () {
    test('daily adds one day', () {
      final next =
          RecurrenceFrequency.daily.nextDate(DateTime(2026, 4, 10));
      expect(next, DateTime(2026, 4, 11));
    });

    test('daily handles month rollover', () {
      final next =
          RecurrenceFrequency.daily.nextDate(DateTime(2026, 4, 30));
      expect(next, DateTime(2026, 5, 1));
    });

    test('daily handles year rollover', () {
      final next =
          RecurrenceFrequency.daily.nextDate(DateTime(2026, 12, 31));
      expect(next, DateTime(2027, 1, 1));
    });

    test('weekly adds seven days', () {
      final next =
          RecurrenceFrequency.weekly.nextDate(DateTime(2026, 4, 10));
      expect(next, DateTime(2026, 4, 17));
    });

    test('weekly crosses month boundary', () {
      final next =
          RecurrenceFrequency.weekly.nextDate(DateTime(2026, 4, 28));
      expect(next, DateTime(2026, 5, 5));
    });

    test('biweekly adds fourteen days', () {
      final next =
          RecurrenceFrequency.biweekly.nextDate(DateTime(2026, 4, 10));
      expect(next, DateTime(2026, 4, 24));
    });

    test('biweekly crosses month boundary', () {
      final next =
          RecurrenceFrequency.biweekly.nextDate(DateTime(2026, 4, 20));
      expect(next, DateTime(2026, 5, 4));
    });

    test('monthly preserves day of month', () {
      final next =
          RecurrenceFrequency.monthly.nextDate(DateTime(2026, 4, 15));
      expect(next, DateTime(2026, 5, 15));
    });

    test('monthly crosses year boundary', () {
      final next =
          RecurrenceFrequency.monthly.nextDate(DateTime(2026, 12, 10));
      expect(next, DateTime(2027, 1, 10));
    });

    test('monthly from Jan 31 rolls over into March', () {
      // DateTime(2026, 2, 31) normalizes to 2026-03-03 in Dart because
      // Feb 2026 only has 28 days. This test documents current behavior.
      final next =
          RecurrenceFrequency.monthly.nextDate(DateTime(2026, 1, 31));
      expect(next, DateTime(2026, 2, 31));
      expect(next.month, 3);
    });

    test('yearly preserves month and day', () {
      final next =
          RecurrenceFrequency.yearly.nextDate(DateTime(2026, 4, 10));
      expect(next, DateTime(2027, 4, 10));
    });

    test('yearly from Feb 29 leap day rolls to Mar 1 next year', () {
      // DateTime(2025, 2, 29) normalizes to 2025-03-01 in Dart because
      // 2025 is not a leap year. This documents current behavior.
      final next =
          RecurrenceFrequency.yearly.nextDate(DateTime(2024, 2, 29));
      expect(next, DateTime(2025, 2, 29));
      expect(next.month, 3);
      expect(next.day, 1);
    });
  });
}
