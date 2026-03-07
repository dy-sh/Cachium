import '../../features/transactions/data/models/transaction.dart';
import '../providers/exchange_rate_provider.dart';

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
    return double.parse((tx.amount / fromRate).toStringAsFixed(2));
  }

  // Fallback to stored conversion rate
  return double.parse((tx.amount * tx.conversionRate).toStringAsFixed(2));
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
  if (tx.currencyCode == tx.mainCurrencyCode) return null;
  if (tx.mainCurrencyCode != currentMainCurrency) return null;

  final currentValue = convertTransactionToMainCurrency(
    tx.amount,
    tx.currencyCode,
    currentMainCurrency,
    rates,
    tx.conversionRate,
  );
  final diff = currentValue - tx.mainCurrencyAmount;
  if (diff.abs() < 0.005) return null;
  return double.parse(diff.toStringAsFixed(2));
}
