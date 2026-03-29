import '../../features/transactions/data/models/transaction.dart';
import '../providers/exchange_rate_provider.dart';

/// ISO 4217 currencies with non-standard decimal places.
/// Most currencies use 2 decimals; these are the exceptions.
const _currencyDecimals = <String, int>{
  // 0 decimal places
  'BIF': 0, 'CLP': 0, 'DJF': 0, 'GNF': 0, 'ISK': 0,
  'JPY': 0, 'KMF': 0, 'KRW': 0, 'PYG': 0, 'RWF': 0,
  'UGX': 0, 'UYI': 0, 'VND': 0, 'VUV': 0, 'XAF': 0,
  'XOF': 0, 'XPF': 0,
  // 3 decimal places
  'BHD': 3, 'IQD': 3, 'JOD': 3, 'KWD': 3, 'LYD': 3,
  'OMR': 3, 'TND': 3,
};

/// Returns the number of decimal places for a given ISO 4217 currency code.
int currencyDecimalPlaces(String currencyCode) {
  return _currencyDecimals[currencyCode] ?? 2;
}

/// Round a currency value to [decimals] places (default 2).
/// If [currencyCode] is provided, uses the ISO 4217 decimal places for that currency.
double roundCurrency(double value, {int decimals = 2, String? currencyCode}) {
  final effectiveDecimals = currencyCode != null
      ? currencyDecimalPlaces(currencyCode)
      : decimals;
  final factor = _factors[effectiveDecimals] ?? _pow10(effectiveDecimals);
  return (value * factor).roundToDouble() / factor;
}

const _factors = {0: 1.0, 1: 10.0, 2: 100.0, 3: 1000.0};

double _pow10(int n) {
  double result = 1;
  for (int i = 0; i < n; i++) {
    result *= 10;
  }
  return result;
}

/// Convert a transaction's amount to the main currency.
///
/// Uses live exchange rates when available, falls back to the transaction's
/// stored conversion rate.
double convertedAmount(
  Transaction tx,
  Map<String, double> rates,
  String mainCurrency,
) {
  if (tx.currencyCode == mainCurrency) return tx.amount;

  final fromRate = rates[tx.currencyCode];
  if (fromRate != null && fromRate > 0) {
    return roundCurrency(tx.amount / fromRate);
  }

  // Fallback to stored conversion rate (live rate unavailable)
  assert(() {
    // ignore: avoid_print
    print('currency_conversion: using stored rate for ${tx.currencyCode} (no live rate available)');
    return true;
  }());
  if (tx.conversionRate <= 0 || !tx.conversionRate.isFinite) {
    // Invalid stored rate — return amount as-is rather than producing NaN/Infinity
    return tx.amount;
  }
  return roundCurrency(tx.amount * tx.conversionRate);
}

/// Convert a transaction's amount to the main currency, with sign.
/// Income is positive, expense is negative, transfer is zero.
double convertedSignedAmount(
  Transaction tx,
  Map<String, double> rates,
  String mainCurrency,
) {
  final amount = convertedAmount(tx, rates, mainCurrency);
  switch (tx.type) {
    case TransactionType.income:
      return amount;
    case TransactionType.expense:
      return -amount;
    case TransactionType.transfer:
      return 0;
  }
}

/// Calculates the conversion gain/loss for a foreign-currency transaction.
///
/// Returns null when:
/// - Transaction is in the same currency as its stored main currency
/// - The app's main currency has changed since the transaction was created
/// - The difference is negligible (< $0.01)
double? conversionGainLoss(
  Transaction tx,
  Map<String, double> rates,
  String currentMainCurrency,
) {
  if (tx.mainCurrencyAmount == null) return null;
  if (tx.currencyCode == tx.mainCurrencyCode) return null;
  if (tx.mainCurrencyCode != currentMainCurrency) return null;

  final currentValue = convertTransactionToMainCurrency(
    tx.amount,
    tx.currencyCode,
    currentMainCurrency,
    rates,
    tx.conversionRate,
  );
  final diff = currentValue - tx.mainCurrencyAmount!;
  // Use currency-aware threshold: half of the smallest unit
  final decimals = currencyDecimalPlaces(currentMainCurrency);
  final threshold = 0.5 / _pow10(decimals);
  if (diff.abs() < threshold) return null;
  return roundCurrency(diff, currencyCode: currentMainCurrency);
}
