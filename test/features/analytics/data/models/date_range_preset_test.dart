import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/date_range_preset.dart';

void main() {
  group('DateRangePreset.displayName', () {
    test('returns correct display names', () {
      expect(DateRangePreset.last7Days.displayName, '7D');
      expect(DateRangePreset.last30Days.displayName, '30D');
      expect(DateRangePreset.thisMonth.displayName, 'Month');
      expect(DateRangePreset.lastMonth.displayName, 'Last Month');
      expect(DateRangePreset.last3Months.displayName, '3M');
      expect(DateRangePreset.last6Months.displayName, '6M');
      expect(DateRangePreset.last12Months.displayName, '12M');
      expect(DateRangePreset.thisYear.displayName, 'Year');
      expect(DateRangePreset.allTime.displayName, 'All');
      expect(DateRangePreset.custom.displayName, 'Custom');
    });
  });

  group('DateRangePreset.getDateRange', () {
    // These tests verify structural properties since the exact dates
    // depend on DateTime.now()

    test('last7Days spans 7 days', () {
      final range = DateRangePreset.last7Days.getDateRange();
      expect(range.dayCount, 7);
    });

    test('last30Days spans 30 days', () {
      final range = DateRangePreset.last30Days.getDateRange();
      expect(range.dayCount, 30);
    });

    test('thisMonth starts on day 1', () {
      final range = DateRangePreset.thisMonth.getDateRange();
      expect(range.start.day, 1);
      expect(range.start.month, DateTime.now().month);
      expect(range.start.year, DateTime.now().year);
    });

    test('lastMonth starts and ends in previous month', () {
      final range = DateRangePreset.lastMonth.getDateRange();
      final now = DateTime.now();
      final expectedMonth = now.month == 1 ? 12 : now.month - 1;
      expect(range.start.day, 1);
      expect(range.start.month, expectedMonth);
      // End day should be last day of last month
      expect(range.end.day, DateTime(now.year, now.month, 0).day);
    });

    test('last3Months starts 2 months back on day 1', () {
      final range = DateRangePreset.last3Months.getDateRange();
      expect(range.start.day, 1);
    });

    test('thisYear starts on January 1', () {
      final range = DateRangePreset.thisYear.getDateRange();
      expect(range.start.month, 1);
      expect(range.start.day, 1);
      expect(range.start.year, DateTime.now().year);
    });

    test('allTime starts from year 2000', () {
      final range = DateRangePreset.allTime.getDateRange();
      expect(range.start.year, 2000);
      expect(range.start.month, 1);
      expect(range.start.day, 1);
    });

    test('custom defaults to 30-day range', () {
      final range = DateRangePreset.custom.getDateRange();
      expect(range.dayCount, 30);
    });

    test('all presets have end >= start', () {
      for (final preset in DateRangePreset.values) {
        final range = preset.getDateRange();
        expect(
          range.end.isAfter(range.start) || range.end == range.start,
          isTrue,
          reason: '${preset.name} has end before start',
        );
      }
    });
  });

  group('DateRange', () {
    test('dayCount calculates correctly', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 10),
      );
      expect(range.dayCount, 10);
    });

    test('dayCount is 1 for same-day range', () {
      final range = DateRange(
        start: DateTime(2026, 3, 15),
        end: DateTime(2026, 3, 15),
      );
      expect(range.dayCount, 1);
    });

    test('contains returns true for date within range', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(range.contains(DateTime(2026, 1, 15)), isTrue);
    });

    test('contains returns true for start date', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(range.contains(DateTime(2026, 1, 1)), isTrue);
    });

    test('contains returns true for end date', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(range.contains(DateTime(2026, 1, 31)), isTrue);
    });

    test('contains returns false for date before range', () {
      final range = DateRange(
        start: DateTime(2026, 1, 5),
        end: DateTime(2026, 1, 31),
      );
      expect(range.contains(DateTime(2026, 1, 4)), isFalse);
    });

    test('contains returns false for date after range', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(range.contains(DateTime(2026, 2, 1)), isFalse);
    });

    test('contains ignores time component', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1, 23, 59),
        end: DateTime(2026, 1, 31, 0, 0),
      );
      expect(range.contains(DateTime(2026, 1, 1, 0, 0)), isTrue);
      expect(range.contains(DateTime(2026, 1, 31, 23, 59)), isTrue);
    });
  });

  group('DateRange equality', () {
    test('equal ranges are equal', () {
      final r1 = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      final r2 = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });

    test('different ranges are not equal', () {
      final r1 = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      final r2 = DateRange(
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 28),
      );
      expect(r1, isNot(equals(r2)));
    });
  });

  group('DateRange.copyWith', () {
    test('updates specified fields', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      final copy = range.copyWith(end: DateTime(2026, 2, 28));
      expect(copy.start, DateTime(2026, 1, 1));
      expect(copy.end, DateTime(2026, 2, 28));
    });
  });
}
