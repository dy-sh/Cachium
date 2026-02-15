enum TransactionType {
  income,
  expense,
  transfer,
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final String? destinationAccountId; // For transfers: the receiving account
  final String? assetId; // Optional link to an asset
  final DateTime date;
  final String? note;
  final String? merchant;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.destinationAccountId,
    this.assetId,
    required this.date,
    this.note,
    this.merchant,
    required this.createdAt,
  });

  bool get isTransfer => type == TransactionType.transfer;

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? destinationAccountId,
    bool clearDestinationAccountId = false,
    String? assetId,
    bool clearAssetId = false,
    DateTime? date,
    String? note,
    String? merchant,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      destinationAccountId: clearDestinationAccountId
          ? null
          : (destinationAccountId ?? this.destinationAccountId),
      assetId: clearAssetId ? null : (assetId ?? this.assetId),
      date: date ?? this.date,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TransactionGroup {
  final DateTime date;
  final List<Transaction> transactions;

  const TransactionGroup({
    required this.date,
    required this.transactions,
  });

  double get netAmount {
    return transactions.fold(0.0, (sum, tx) {
      if (tx.type == TransactionType.income) {
        return sum + tx.amount;
      } else if (tx.type == TransactionType.expense) {
        return sum - tx.amount;
      }
      // Transfers are net zero
      return sum;
    });
  }

  double get totalIncome {
    return transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
}
