import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/utils/date_formatter.dart';
import 'package:cachium/features/settings/data/models/app_settings.dart';

void main() {
  group('DateFormatter.formatFull', () {
    test('formats date correctly', () {
      expect(
        DateFormatter.formatFull(DateTime(2024, 1, 15)),
        'January 15, 2024',
      );
    });

    test('formats single-digit day', () {
      expect(
        DateFormatter.formatFull(DateTime(2024, 3, 5)),
        'March 5, 2024',
      );
    });
  });

  group('DateFormatter.formatShort', () {
    test('formats date correctly', () {
      expect(DateFormatter.formatShort(DateTime(2024, 1, 15)), 'Jan 15');
    });

    test('formats different month', () {
      expect(DateFormatter.formatShort(DateTime(2024, 12, 25)), 'Dec 25');
    });
  });

  group('DateFormatter.formatTime', () {
    test('formats PM time', () {
      expect(
        DateFormatter.formatTime(DateTime(2024, 1, 1, 14, 30)),
        '2:30 PM',
      );
    });

    test('formats AM time', () {
      expect(
        DateFormatter.formatTime(DateTime(2024, 1, 1, 9, 5)),
        '9:05 AM',
      );
    });

    test('formats noon', () {
      expect(
        DateFormatter.formatTime(DateTime(2024, 1, 1, 12, 0)),
        '12:00 PM',
      );
    });
  });

  group('DateFormatter.formatMonthYear', () {
    test('formats correctly', () {
      expect(
        DateFormatter.formatMonthYear(DateTime(2024, 6, 15)),
        'June 2024',
      );
    });
  });

  group('DateFormatter.formatWithOption', () {
    final date = DateTime(2024, 3, 15);

    test('MM/DD/YYYY format', () {
      expect(
        DateFormatter.formatWithOption(date, DateFormatOption.mmddyyyy),
        '3/15/2024',
      );
    });

    test('DD/MM/YYYY format', () {
      expect(
        DateFormatter.formatWithOption(date, DateFormatOption.ddmmyyyy),
        '15/3/2024',
      );
    });

    test('DD.MM.YYYY format', () {
      expect(
        DateFormatter.formatWithOption(date, DateFormatOption.ddmmyyyyDot),
        '15.3.2024',
      );
    });

    test('YYYY-MM-DD format', () {
      expect(
        DateFormatter.formatWithOption(date, DateFormatOption.yyyymmdd),
        '2024-03-15',
      );
    });
  });

  group('DateFormatter.isSameDay', () {
    test('same day returns true', () {
      expect(
        DateFormatter.isSameDay(
          DateTime(2024, 3, 15, 10, 30),
          DateTime(2024, 3, 15, 20, 0),
        ),
        isTrue,
      );
    });

    test('different day returns false', () {
      expect(
        DateFormatter.isSameDay(DateTime(2024, 3, 15), DateTime(2024, 3, 16)),
        isFalse,
      );
    });

    test('different month returns false', () {
      expect(
        DateFormatter.isSameDay(DateTime(2024, 3, 15), DateTime(2024, 4, 15)),
        isFalse,
      );
    });

    test('different year returns false', () {
      expect(
        DateFormatter.isSameDay(DateTime(2024, 3, 15), DateTime(2025, 3, 15)),
        isFalse,
      );
    });
  });
}
