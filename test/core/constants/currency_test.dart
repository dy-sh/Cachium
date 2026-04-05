import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/constants/currencies.dart';

void main() {
  group('Currency.fromCode', () {
    test('returns USD for valid code', () {
      final currency = Currency.fromCode('USD');
      expect(currency.code, 'USD');
      expect(currency.symbol, '\$');
      expect(currency.name, 'US Dollar');
    });

    test('returns EUR for valid code', () {
      final currency = Currency.fromCode('EUR');
      expect(currency.code, 'EUR');
      expect(currency.name, 'Euro');
    });

    test('returns JPY for valid code', () {
      final currency = Currency.fromCode('JPY');
      expect(currency.code, 'JPY');
    });

    test('returns default (USD) for unknown code', () {
      final currency = Currency.fromCode('XYZ');
      expect(currency.code, 'USD');
      expect(currency.symbol, '\$');
    });

    test('returns default for empty code', () {
      final currency = Currency.fromCode('');
      expect(currency.code, 'USD');
    });
  });

  group('Currency.symbolFromCode', () {
    test('returns correct symbol for known currencies', () {
      expect(Currency.symbolFromCode('USD'), '\$');
      expect(Currency.symbolFromCode('GBP'), '\u00A3');
      expect(Currency.symbolFromCode('JPY'), '\u00A5');
    });

    test('returns USD symbol for unknown code', () {
      expect(Currency.symbolFromCode('UNKNOWN'), '\$');
    });
  });

  group('Currency equality', () {
    test('currencies with same code are equal', () {
      final c1 = Currency.fromCode('USD');
      final c2 = Currency.fromCode('USD');
      expect(c1, equals(c2));
    });

    test('currencies with different codes are not equal', () {
      final c1 = Currency.fromCode('USD');
      final c2 = Currency.fromCode('EUR');
      expect(c1, isNot(equals(c2)));
    });
  });

  group('Currency.all', () {
    test('contains common currencies', () {
      final codes = Currency.all.map((c) => c.code).toSet();
      expect(codes, contains('USD'));
      expect(codes, contains('EUR'));
      expect(codes, contains('GBP'));
      expect(codes, contains('JPY'));
      expect(codes, contains('CHF'));
    });

    test('all entries have non-empty fields', () {
      for (final currency in Currency.all) {
        expect(currency.code, isNotEmpty);
        expect(currency.symbol, isNotEmpty);
        expect(currency.name, isNotEmpty);
        expect(currency.flag, isNotEmpty);
      }
    });

    test('all codes are 3 characters', () {
      for (final currency in Currency.all) {
        expect(currency.code.length, 3);
      }
    });
  });
}
