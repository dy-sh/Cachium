import '../../features/transactions/data/models/transaction.dart';
import 'currency_conversion.dart';

/// Calculate the balance deltas that a single transaction applies to accounts.
///
/// Returns a map of accountId -> delta:
/// - Income: source account credited by +amount
/// - Expense: source account debited by -amount
/// - Transfer: source debited by -amount, destination credited by destinationAmount ?? amount
Map<String, double> transactionDeltas(Transaction tx) {
  final Map<String, double> deltas = {};
  switch (tx.type) {
    case TransactionType.income:
      deltas[tx.accountId] = tx.amount;
    case TransactionType.expense:
      deltas[tx.accountId] = -tx.amount;
    case TransactionType.transfer:
      deltas[tx.accountId] = -tx.amount;
      if (tx.destinationAccountId != null) {
        deltas[tx.destinationAccountId!] = tx.destinationAmount ?? tx.amount;
      }
  }
  return deltas;
}

/// Calculate the balance deltas needed to reverse (undo) a transaction.
///
/// This is the negation of [transactionDeltas] — used when deleting
/// or replacing a transaction to undo its balance effects.
Map<String, double> reverseTransactionDeltas(Transaction tx) {
  return transactionDeltas(tx).map((id, delta) => MapEntry(id, -delta));
}

/// Calculate per-account balance deltas from a list of transactions.
///
/// Handles income (credit), expense (debit), and transfer
/// (debit source, credit destination with [destinationAmount] ?? [amount]).
/// Returns a map of accountId -> delta.
Map<String, double> calculateAccountDeltas(List<Transaction> transactions) {
  final Map<String, double> deltas = {};

  for (final tx in transactions) {
    for (final entry in transactionDeltas(tx).entries) {
      deltas[entry.key] = (deltas[entry.key] ?? 0) + entry.value;
    }
  }

  // Round all deltas
  return deltas.map((key, value) => MapEntry(key, roundCurrency(value)));
}
