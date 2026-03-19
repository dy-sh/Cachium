import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/utils/currency_conversion.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';

Transaction _makeTx({
  double amount = 100.0,
  TransactionType type = TransactionType.expense,
  String currencyCode = 'USD',
  double conversionRate = 1.0,
  String mainCurrencyCode = 'USD',
  double? mainCurrencyAmount,
}) {
  final now = DateTime.now();
  return Transaction(
    id: 'tx-1',
    amount: amount,
    type: type,
    categoryId: 'cat-1',
    accountId: 'acc-1',
    currencyCode: currencyCode,
    conversionRate: conversionRate,
    mainCurrencyCode: mainCurrencyCode,
    mainCurrencyAmount: mainCurrencyAmount,
    date: now,
    createdAt: now,
  );
}

void main() {
  // ── roundCurrency ──────────────────────────────────────────────────

  group('roundCurrency', () {
    test('rounds to 2 decimal places by default', () {
      // Note: 1.005 in IEEE 754 is actually 1.00499... so it rounds to 1.0
      expect(roundCurrency(1.006), 1.01);
      expect(roundCurrency(1.004), 1.0);
      expect(roundCurrency(99.999), 100.0);
      expect(roundCurrency(2.345), 2.35);
    });

    test('handles zero', () {
      expect(roundCurrency(0.0), 0.0);
    });

    test('handles negative values', () {
      expect(roundCurrency(-1.006), -1.01);
      expect(roundCurrency(-99.999), -100.0);
      expect(roundCurrency(-2.345), -2.35);
    });

    test('rounds to 0 decimal places', () {
      expect(roundCurrency(1.5, decimals: 0), 2.0);
      expect(roundCurrency(1.4, decimals: 0), 1.0);
    });

    test('rounds to 1 decimal place', () {
      expect(roundCurrency(1.05, decimals: 1), 1.1);
      expect(roundCurrency(1.04, decimals: 1), 1.0);
    });

    test('rounds to 3 decimal places', () {
      expect(roundCurrency(1.0005, decimals: 3), 1.001);
      expect(roundCurrency(1.0004, decimals: 3), 1.0);
    });

    test('rounds to a non-cached decimal count (e.g. 4)', () {
      expect(roundCurrency(1.00005, decimals: 4), 1.0001);
    });

    test('large values round correctly', () {
      expect(roundCurrency(123456789.125), 123456789.13);
    });

    test('very small values', () {
      expect(roundCurrency(0.001), 0.0);
      expect(roundCurrency(0.005), 0.01);
    });

    test('rounds JPY to 0 decimal places via currencyCode', () {
      expect(roundCurrency(1234.5, currencyCode: 'JPY'), 1235.0);
      expect(roundCurrency(1234.4, currencyCode: 'JPY'), 1234.0);
    });

    test('rounds KWD to 3 decimal places via currencyCode', () {
      expect(roundCurrency(1.2345, currencyCode: 'KWD'), 1.235);
      expect(roundCurrency(1.2344, currencyCode: 'KWD'), 1.234);
    });

    test('rounds USD to 2 decimal places via currencyCode', () {
      expect(roundCurrency(1.235, currencyCode: 'USD'), 1.24);
    });

    test('currencyCode overrides decimals parameter', () {
      // Even if decimals=2 is default, currencyCode for JPY should give 0
      expect(roundCurrency(100.5, currencyCode: 'JPY'), 101.0);
    });
  });

  group('currencyDecimalPlaces', () {
    test('returns 0 for JPY', () {
      expect(currencyDecimalPlaces('JPY'), 0);
    });

    test('returns 3 for KWD', () {
      expect(currencyDecimalPlaces('KWD'), 3);
    });

    test('returns 2 for USD (default)', () {
      expect(currencyDecimalPlaces('USD'), 2);
    });

    test('returns 2 for EUR (default)', () {
      expect(currencyDecimalPlaces('EUR'), 2);
    });
  });

  // ── convertedAmount ────────────────────────────────────────────────

  group('convertedAmount', () {
    test('returns amount as-is when currency matches main currency', () {
      final tx = _makeTx(amount: 50.0, currencyCode: 'USD');
      expect(convertedAmount(tx, {}, 'USD'), 50.0);
    });

    test('converts using live exchange rate when available', () {
      // EUR rate = 0.9 means 1 USD = 0.9 EUR, so 90 EUR / 0.9 = 100 USD
      final tx = _makeTx(
        amount: 90.0,
        currencyCode: 'EUR',
        conversionRate: 0.5,
      );
      final rates = {'EUR': 0.9};
      expect(convertedAmount(tx, rates, 'USD'), 100.0);
    });

    test('falls back to stored conversion rate when no live rate', () {
      final tx = _makeTx(
        amount: 100.0,
        currencyCode: 'EUR',
        conversionRate: 0.85,
      );
      // amount * conversionRate = 100 * 0.85 = 85.0
      expect(convertedAmount(tx, {}, 'USD'), 85.0);
    });

    test('falls back to stored rate when live rate is zero', () {
      final tx = _makeTx(
        amount: 100.0,
        currencyCode: 'EUR',
        conversionRate: 0.85,
      );
      final rates = {'EUR': 0.0};
      expect(convertedAmount(tx, rates, 'USD'), 85.0);
    });

    test('falls back to stored rate when live rate is negative', () {
      final tx = _makeTx(
        amount: 100.0,
        currencyCode: 'EUR',
        conversionRate: 0.85,
      );
      final rates = {'EUR': -1.0};
      expect(convertedAmount(tx, rates, 'USD'), 85.0);
    });

    test('result is rounded to 2 decimal places', () {
      // 100 / 3 = 33.333...
      final tx = _makeTx(
        amount: 100.0,
        currencyCode: 'GBP',
        conversionRate: 1.0,
      );
      final rates = {'GBP': 3.0};
      expect(convertedAmount(tx, rates, 'USD'), 33.33);
    });
  });

  // ── conversionGainLoss ─────────────────────────────────────────────

  group('conversionGainLoss', () {
    test('returns null when mainCurrencyAmount is null', () {
      final tx = _makeTx(
        currencyCode: 'EUR',
        mainCurrencyCode: 'USD',
        mainCurrencyAmount: null,
      );
      expect(conversionGainLoss(tx, {}, 'USD'), isNull);
    });

    test('returns null when currencyCode == mainCurrencyCode (same currency)',
        () {
      final tx = _makeTx(
        currencyCode: 'USD',
        mainCurrencyCode: 'USD',
        mainCurrencyAmount: 100.0,
      );
      expect(conversionGainLoss(tx, {}, 'USD'), isNull);
    });

    test(
        'returns null when stored mainCurrencyCode differs from current main currency',
        () {
      final tx = _makeTx(
        currencyCode: 'EUR',
        mainCurrencyCode: 'GBP',
        mainCurrencyAmount: 85.0,
      );
      // Current main is USD, but tx was saved with GBP as main
      expect(conversionGainLoss(tx, {'EUR': 0.9}, 'USD'), isNull);
    });

    test('returns null when difference is negligible (< 0.005)', () {
      // amount=100 EUR, stored mainCurrencyAmount=111.11 USD
      // With rate EUR=0.9, current value = 100/0.9 = 111.11
      final tx = _makeTx(
        amount: 100.0,
        currencyCode: 'EUR',
        conversionRate: 0.9,
        mainCurrencyCode: 'USD',
        mainCurrencyAmount: 111.11,
      );
      final rates = {'EUR': 0.9};
      expect(conversionGainLoss(tx, rates, 'USD'), isNull);
    });

    test('returns positive gain when currency appreciated', () {
      // Saved at rate 0.9 -> mainCurrencyAmount = 100/0.9 = 111.11
      // Now rate is 0.8 -> current value = 100/0.8 = 125.0
      // gain = 125.0 - 111.11 = 13.89
      final tx = _makeTx(
        amount: 100.0,
        currencyCode: 'EUR',
        conversionRate: 0.9,
        mainCurrencyCode: 'USD',
        mainCurrencyAmount: 111.11,
      );
      final rates = {'EUR': 0.8};
      expect(conversionGainLoss(tx, rates, 'USD'), 13.89);
    });

    test('returns negative loss when currency depreciated', () {
      // Saved at mainCurrencyAmount = 125.0
      // Now rate is 0.9 -> current value = 100/0.9 = 111.11
      // loss = 111.11 - 125.0 = -13.89
      final tx = _makeTx(
        amount: 100.0,
        currencyCode: 'EUR',
        conversionRate: 0.8,
        mainCurrencyCode: 'USD',
        mainCurrencyAmount: 125.0,
      );
      final rates = {'EUR': 0.9};
      expect(conversionGainLoss(tx, rates, 'USD'), -13.89);
    });

    test('uses stored conversionRate as fallback when no live rate', () {
      // No live rate -> uses amount * storedConversionRate = 100 * 0.85 = 85.0
      // diff = 85.0 - 90.0 = -5.0
      final tx = _makeTx(
        amount: 100.0,
        currencyCode: 'EUR',
        conversionRate: 0.85,
        mainCurrencyCode: 'USD',
        mainCurrencyAmount: 90.0,
      );
      expect(conversionGainLoss(tx, {}, 'USD'), -5.0);
    });
  });
}
