import '../../features/transactions/data/models/transaction.dart';
import '../providers/exchange_rate_provider.dart';

/// Round a currency value to [decimals] places (default 2).
double roundCurrency(double value, {int decimals = 2}) {
  final factor = _factors[decimals] ?? _pow10(decimals);
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

  // Fallback to stored conversion rate
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
  if (diff.abs() < 0.005) return null;
  return roundCurrency(diff);
}
