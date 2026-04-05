import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('formats positive amount with USD symbol', () {
      expect(CurrencyFormatter.format(1234.56), '\$1,234.56');
    });

    test('formats negative amount', () {
      expect(CurrencyFormatter.format(-500.0), '-\$500.00');
    });

    test('formats zero', () {
      expect(CurrencyFormatter.format(0.0), '\$0.00');
    });

    test('formats with EUR symbol', () {
      final result = CurrencyFormatter.format(100.0, currencyCode: 'EUR');
      expect(result, contains('100.00'));
    });

    test('formats large amount with comma separators', () {
      expect(CurrencyFormatter.format(1000000.0), '\$1,000,000.00');
    });
  });

  group('CurrencyFormatter.formatCompact', () {
    test('formats thousands', () {
      final result = CurrencyFormatter.formatCompact(1500.0);
      expect(result, '\$1.5K');
    });

    test('formats millions', () {
      final result = CurrencyFormatter.formatCompact(1500000.0);
      expect(result, '\$1.5M');
    });

    test('formats small amount without suffix', () {
      final result = CurrencyFormatter.formatCompact(50.0);
      expect(result, contains('50'));
    });
  });

  group('CurrencyFormatter.formatWithSign', () {
    test('adds + for income', () {
      final result = CurrencyFormatter.formatWithSign(100.0, 'income');
      expect(result, startsWith('+'));
      expect(result, contains('100.00'));
    });

    test('adds - for expense', () {
      final result = CurrencyFormatter.formatWithSign(100.0, 'expense');
      expect(result, startsWith('-'));
      expect(result, contains('100.00'));
    });

    test('no sign for transfer', () {
      final result = CurrencyFormatter.formatWithSign(100.0, 'transfer');
      expect(result, isNot(startsWith('+')));
      expect(result, isNot(startsWith('-')));
    });

    test('uses absolute value of amount', () {
      final result = CurrencyFormatter.formatWithSign(-100.0, 'income');
      expect(result, '+\$100.00');
    });
  });

  group('CurrencyFormatter.formatSimple', () {
    test('omits decimals for whole numbers', () {
      final result = CurrencyFormatter.formatSimple(100.0);
      expect(result, '\$100');
    });

    test('includes decimals for fractional amounts', () {
      final result = CurrencyFormatter.formatSimple(99.50);
      expect(result, '\$99.50');
    });

    test('formats zero as whole number', () {
      final result = CurrencyFormatter.formatSimple(0.0);
      expect(result, '\$0');
    });
  });
}
