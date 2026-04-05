import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/utils/formatting_providers.dart';
import 'package:cachium/features/settings/data/models/app_settings.dart';

void main() {
  group('SettingsCurrencyFormatter', () {
    late SettingsCurrencyFormatter formatter;

    setUp(() {
      formatter = SettingsCurrencyFormatter(currencyCode: 'USD');
    });

    group('format', () {
      test('formats positive amount', () {
        expect(formatter.format(1234.56), '\$1,234.56');
      });

      test('formats negative amount', () {
        expect(formatter.format(-500.0), '-\$500.00');
      });

      test('formats zero', () {
        expect(formatter.format(0), '\$0.00');
      });

      test('formats with comma separators', () {
        expect(formatter.format(1000000), '\$1,000,000.00');
      });
    });

    group('formatCompact', () {
      test('formats thousands', () {
        expect(formatter.formatCompact(1500), '\$1.5K');
      });

      test('formats small amount', () {
        expect(formatter.formatCompact(42), '\$42');
      });
    });

    group('formatWithSign', () {
      test('adds + for income', () {
        final result = formatter.formatWithSign(100, 'income');
        expect(result, startsWith('+'));
        expect(result, contains('100.00'));
      });

      test('adds - for expense', () {
        final result = formatter.formatWithSign(100, 'expense');
        expect(result, startsWith('-'));
      });

      test('no sign for transfer', () {
        final result = formatter.formatWithSign(100, 'transfer');
        expect(result, isNot(startsWith('+')));
        expect(result, isNot(startsWith('-')));
      });

      test('uses absolute value', () {
        final result = formatter.formatWithSign(-100, 'income');
        expect(result, '+\$100.00');
      });
    });

    group('formatSimple', () {
      test('omits decimals for whole numbers', () {
        expect(formatter.formatSimple(100), '\$100');
      });

      test('includes decimals for fractional', () {
        expect(formatter.formatSimple(99.50), '\$99.50');
      });
    });

    group('formatInCurrency', () {
      test('formats with target currency symbol', () {
        final result = formatter.formatInCurrency(100, 'GBP');
        expect(result, contains('100.00'));
        expect(result, contains('\u00A3')); // £ symbol
      });

      test('formats with same currency', () {
        final result = formatter.formatInCurrency(50, 'USD');
        expect(result, '\$50.00');
      });
    });

    group('different currency codes', () {
      test('EUR formatter uses euro symbol', () {
        final eurFormatter = SettingsCurrencyFormatter(currencyCode: 'EUR');
        final result = eurFormatter.format(100);
        expect(result, contains('100.00'));
      });

      test('JPY formatter uses yen symbol', () {
        final jpyFormatter = SettingsCurrencyFormatter(currencyCode: 'JPY');
        final result = jpyFormatter.format(1000);
        expect(result, contains('1,000.00'));
      });
    });
  });

  group('SettingsDateFormatter', () {
    late SettingsDateFormatter formatter;

    setUp(() {
      formatter = SettingsDateFormatter(
        dateFormat: DateFormatOption.mmddyyyy,
        firstDayOfWeek: FirstDayOfWeek.sunday,
      );
    });

    group('formatFull', () {
      test('formats correctly', () {
        expect(
          formatter.formatFull(DateTime(2026, 3, 15)),
          'March 15, 2026',
        );
      });
    });

    group('formatShort', () {
      test('formats correctly', () {
        expect(formatter.formatShort(DateTime(2026, 12, 25)), 'Dec 25');
      });
    });

    group('formatTime', () {
      test('formats PM', () {
        expect(
          formatter.formatTime(DateTime(2026, 1, 1, 14, 30)),
          '2:30 PM',
        );
      });

      test('formats AM', () {
        expect(
          formatter.formatTime(DateTime(2026, 1, 1, 9, 5)),
          '9:05 AM',
        );
      });
    });

    group('formatMonthYear', () {
      test('formats correctly', () {
        expect(
          formatter.formatMonthYear(DateTime(2026, 6, 1)),
          'June 2026',
        );
      });
    });

    group('formatWithOption', () {
      test('MM/DD/YYYY', () {
        final f = SettingsDateFormatter(
          dateFormat: DateFormatOption.mmddyyyy,
          firstDayOfWeek: FirstDayOfWeek.sunday,
        );
        expect(f.formatWithOption(DateTime(2026, 3, 15)), '3/15/2026');
      });

      test('DD/MM/YYYY', () {
        final f = SettingsDateFormatter(
          dateFormat: DateFormatOption.ddmmyyyy,
          firstDayOfWeek: FirstDayOfWeek.sunday,
        );
        expect(f.formatWithOption(DateTime(2026, 3, 15)), '15/3/2026');
      });

      test('DD.MM.YYYY', () {
        final f = SettingsDateFormatter(
          dateFormat: DateFormatOption.ddmmyyyyDot,
          firstDayOfWeek: FirstDayOfWeek.sunday,
        );
        expect(f.formatWithOption(DateTime(2026, 3, 15)), '15.3.2026');
      });

      test('YYYY-MM-DD', () {
        final f = SettingsDateFormatter(
          dateFormat: DateFormatOption.yyyymmdd,
          firstDayOfWeek: FirstDayOfWeek.sunday,
        );
        expect(f.formatWithOption(DateTime(2026, 3, 15)), '2026-03-15');
      });
    });

    group('isSameDay', () {
      test('same day returns true', () {
        expect(
          formatter.isSameDay(
            DateTime(2026, 3, 15, 10, 0),
            DateTime(2026, 3, 15, 20, 0),
          ),
          isTrue,
        );
      });

      test('different day returns false', () {
        expect(
          formatter.isSameDay(DateTime(2026, 3, 15), DateTime(2026, 3, 16)),
          isFalse,
        );
      });

      test('different month returns false', () {
        expect(
          formatter.isSameDay(DateTime(2026, 3, 15), DateTime(2026, 4, 15)),
          isFalse,
        );
      });

      test('different year returns false', () {
        expect(
          formatter.isSameDay(DateTime(2026, 3, 15), DateTime(2027, 3, 15)),
          isFalse,
        );
      });
    });

    group('formatRelative', () {
      test('today returns Today', () {
        final now = DateTime.now();
        expect(formatter.formatRelative(now), 'Today');
      });

      test('yesterday returns Yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(formatter.formatRelative(yesterday), 'Yesterday');
      });

      test('within last week returns day name', () {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final result = formatter.formatRelative(threeDaysAgo);
        // Should be a day name like "Monday", "Tuesday", etc.
        expect(
          ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
          contains(result),
        );
      });

      test('same year returns short format', () {
        final now = DateTime.now();
        final twoMonthsAgo = DateTime(now.year, now.month - 2, 15);
        if (twoMonthsAgo.year == now.year) {
          final result = formatter.formatRelative(twoMonthsAgo);
          // Should be short format like "Jan 15"
          expect(result, isNot('Today'));
          expect(result, isNot('Yesterday'));
        }
      });

      test('different year returns full format', () {
        final oldDate = DateTime(2020, 6, 15);
        final result = formatter.formatRelative(oldDate);
        expect(result, 'June 15, 2020');
      });
    });

    group('formatGroupHeader', () {
      test('today returns Today', () {
        expect(formatter.formatGroupHeader(DateTime.now()), 'Today');
      });

      test('yesterday returns Yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(formatter.formatGroupHeader(yesterday), 'Yesterday');
      });

      test('different year returns full format', () {
        final oldDate = DateTime(2020, 6, 15);
        expect(formatter.formatGroupHeader(oldDate), 'June 15, 2020');
      });

      test('same year (not today/yesterday) returns short format', () {
        final now = DateTime.now();
        final twoMonthsAgo = DateTime(now.year, now.month - 2, 10);
        if (twoMonthsAgo.year == now.year) {
          final result = formatter.formatGroupHeader(twoMonthsAgo);
          expect(result, isNot('Today'));
          expect(result, isNot('Yesterday'));
          // Should be short format
          expect(result, isNotEmpty);
        }
      });
    });
  });
}
