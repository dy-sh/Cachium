import '../../features/transactions/data/models/transaction.dart';

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
    return tx.amount / fromRate;
  }

  // Fallback to stored conversion rate
  return tx.amount * tx.conversionRate;
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
