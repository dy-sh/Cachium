import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/settings/data/models/app_settings.dart';

void main() {
  group('ThemeModeOption.displayName', () {
    test('returns correct values', () {
      expect(ThemeModeOption.dark.displayName, 'Dark');
      expect(ThemeModeOption.light.displayName, 'Light');
      expect(ThemeModeOption.system.displayName, 'System');
    });
  });

  group('AmountDisplaySize.displayName', () {
    test('returns correct values', () {
      expect(AmountDisplaySize.large.displayName, 'Large');
      expect(AmountDisplaySize.small.displayName, 'Small');
    });
  });

  group('CategorySortOption.displayName', () {
    test('returns correct values', () {
      expect(CategorySortOption.lastUsed.displayName, 'Last Used');
      expect(CategorySortOption.listOrder.displayName, 'List Order');
      expect(CategorySortOption.alphabetical.displayName, 'Alphabetical');
    });
  });

  group('AssetSortOption.displayName', () {
    test('returns correct values', () {
      expect(AssetSortOption.lastUsed.displayName, 'Last Used');
      expect(AssetSortOption.listOrder.displayName, 'List Order');
      expect(AssetSortOption.alphabetical.displayName, 'Alphabetical');
      expect(AssetSortOption.newest.displayName, 'Newest');
    });
  });

  group('AutoLockTimeout', () {
    test('displayName returns correct values', () {
      expect(AutoLockTimeout.immediate.displayName, 'Immediately');
      expect(AutoLockTimeout.after30Seconds.displayName, 'After 30 Seconds');
      expect(AutoLockTimeout.after1Minute.displayName, 'After 1 Minute');
      expect(AutoLockTimeout.after5Minutes.displayName, 'After 5 Minutes');
      expect(AutoLockTimeout.after15Minutes.displayName, 'After 15 Minutes');
      expect(AutoLockTimeout.never.displayName, 'Never');
    });

    test('duration returns correct values', () {
      expect(AutoLockTimeout.immediate.duration, isNull);
      expect(AutoLockTimeout.after30Seconds.duration, const Duration(seconds: 30));
      expect(AutoLockTimeout.after1Minute.duration, const Duration(minutes: 1));
      expect(AutoLockTimeout.after5Minutes.duration, const Duration(minutes: 5));
      expect(AutoLockTimeout.after15Minutes.duration, const Duration(minutes: 15));
      expect(AutoLockTimeout.never.duration, isNull);
    });
  });

  group('ExchangeRateApiOption.displayName', () {
    test('returns correct values', () {
      expect(ExchangeRateApiOption.frankfurter.displayName, 'Frankfurter (ECB)');
      expect(ExchangeRateApiOption.exchangeRateHost.displayName, 'Open ER-API');
      expect(ExchangeRateApiOption.manual.displayName, 'Manual / Offline');
    });
  });

  group('DateFormatOption', () {
    test('label returns correct values', () {
      expect(DateFormatOption.mmddyyyy.label, 'MM/DD/YYYY');
      expect(DateFormatOption.ddmmyyyy.label, 'DD/MM/YYYY');
      expect(DateFormatOption.ddmmyyyyDot.label, 'DD.MM.YYYY');
      expect(DateFormatOption.yyyymmdd.label, 'YYYY-MM-DD');
    });

    test('pattern returns correct intl patterns', () {
      expect(DateFormatOption.mmddyyyy.pattern, 'M/d/yyyy');
      expect(DateFormatOption.ddmmyyyy.pattern, 'd/M/yyyy');
      expect(DateFormatOption.ddmmyyyyDot.pattern, 'd.M.yyyy');
      expect(DateFormatOption.yyyymmdd.pattern, 'yyyy-MM-dd');
    });
  });

  group('StartScreen', () {
    test('route returns correct values', () {
      expect(StartScreen.home.route, '/');
      expect(StartScreen.transactions.route, '/transactions');
      expect(StartScreen.accounts.route, '/accounts');
    });
  });

  group('FirstDayOfWeek', () {
    test('value returns correct day numbers', () {
      expect(FirstDayOfWeek.sunday.value, DateTime.sunday);
      expect(FirstDayOfWeek.monday.value, DateTime.monday);
    });
  });
}
