import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/demo/demo_data.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../data/models/transaction.dart';

class TransactionsNotifier extends Notifier<List<Transaction>> {
  final _uuid = const Uuid();

  @override
  List<Transaction> build() {
    return List.from(DemoData.transactions);
  }

  void addTransaction({
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String accountId,
    required DateTime date,
    String? note,
  }) {
    final transaction = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );

    state = [transaction, ...state];

    // Update account balance
    final balanceChange = type == TransactionType.income ? amount : -amount;
    ref.read(accountsProvider.notifier).updateBalance(accountId, balanceChange);
  }

  void updateTransaction(Transaction transaction) {
    state = state.map((t) => t.id == transaction.id ? transaction : t).toList();
  }

  void deleteTransaction(String id) {
    final transaction = state.firstWhere((t) => t.id == id);
    state = state.where((t) => t.id != id).toList();

    // Reverse the balance change
    final balanceChange = transaction.type == TransactionType.income
        ? -transaction.amount
        : transaction.amount;
    ref.read(accountsProvider.notifier).updateBalance(
          transaction.accountId,
          balanceChange,
        );
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

enum TransactionFilter { all, income, expense }

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  return TransactionFilter.all;
});

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);

  switch (filter) {
    case TransactionFilter.income:
      return transactions.where((t) => t.type == TransactionType.income).toList();
    case TransactionFilter.expense:
      return transactions.where((t) => t.type == TransactionType.expense).toList();
    case TransactionFilter.all:
      return transactions;
  }
});

final groupedTransactionsProvider = Provider<List<TransactionGroup>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);

  // Sort by date descending
  final sorted = List<Transaction>.from(transactions)
    ..sort((a, b) => b.date.compareTo(a.date));

  // Group by date
  final Map<DateTime, List<Transaction>> grouped = {};
  for (final tx in sorted) {
    final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
    grouped.putIfAbsent(dateKey, () => []).add(tx);
  }

  return grouped.entries
      .map((e) => TransactionGroup(date: e.key, transactions: e.value))
      .toList();
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider);

  // Sort by date descending and take first 5
  final sorted = List<Transaction>.from(transactions)
    ..sort((a, b) => b.date.compareTo(a.date));

  return sorted.take(5).toList();
});

final transactionSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedTransactionsProvider = Provider<List<TransactionGroup>>((ref) {
  final groups = ref.watch(groupedTransactionsProvider);
  final query = ref.watch(transactionSearchQueryProvider).toLowerCase();

  if (query.isEmpty) return groups;

  return groups.map((group) {
    final filteredTxs = group.transactions.where((tx) {
      final note = tx.note?.toLowerCase() ?? '';
      return note.contains(query);
    }).toList();

    return TransactionGroup(date: group.date, transactions: filteredTxs);
  }).where((group) => group.transactions.isNotEmpty).toList();
});
