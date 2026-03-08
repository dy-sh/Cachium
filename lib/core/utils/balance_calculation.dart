import '../../features/transactions/data/models/transaction.dart';
import 'currency_conversion.dart';

/// Calculate per-account balance deltas from a list of transactions.
///
/// Handles income (credit), expense (debit), and transfer
/// (debit source, credit destination with [destinationAmount] ?? [amount]).
/// Returns a map of accountId -> delta.
Map<String, double> calculateAccountDeltas(List<Transaction> transactions) {
  final Map<String, double> deltas = {};

  for (final tx in transactions) {
    switch (tx.type) {
      case TransactionType.income:
        deltas[tx.accountId] = (deltas[tx.accountId] ?? 0) + tx.amount;
        break;
      case TransactionType.expense:
        deltas[tx.accountId] = (deltas[tx.accountId] ?? 0) - tx.amount;
        break;
      case TransactionType.transfer:
        // Debit source account
        deltas[tx.accountId] = (deltas[tx.accountId] ?? 0) - tx.amount;
        // Credit destination account
        if (tx.destinationAccountId != null) {
          final creditAmount = tx.destinationAmount ?? tx.amount;
          deltas[tx.destinationAccountId!] =
              (deltas[tx.destinationAccountId!] ?? 0) + creditAmount;
        }
        break;
    }
  }

  // Round all deltas
  return deltas.map((key, value) => MapEntry(key, roundCurrency(value)));
}
