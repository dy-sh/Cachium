import '../../../../core/utils/currency_conversion.dart';

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
  final String currencyCode;

  /// Multiplier: `amount * conversionRate ≈ mainCurrencyAmount`.
  /// Stored at creation time so gain/loss can be computed later.
  final double conversionRate;

  final double? destinationAmount; // For cross-currency transfers: amount in destination currency
  final String mainCurrencyCode; // App's main currency when transaction was created

  /// Snapshot of `amount` converted to the main currency at creation time.
  /// Null for legacy records created before this field was introduced.
  final double? mainCurrencyAmount;
  final DateTime date;
  final String? note;
  final String? merchant;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.destinationAccountId,
    this.assetId,
    this.currencyCode = 'USD',
    this.conversionRate = 1.0,
    this.destinationAmount,
    this.mainCurrencyCode = 'USD',
    this.mainCurrencyAmount,
    required this.date,
    this.note,
    this.merchant,
    required this.createdAt,
  })  : assert(amount >= 0, 'Transaction amount must be non-negative'),
        assert(conversionRate > 0 && conversionRate.isFinite,
            'Conversion rate must be positive and finite'),
        assert(destinationAmount == null || destinationAmount >= 0,
            'Destination amount must be non-negative'),
        assert(currencyCode.length == 3, 'Currency code must be 3 characters'),
        assert(mainCurrencyCode.length == 3,
            'Main currency code must be 3 characters');

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
    String? currencyCode,
    double? conversionRate,
    double? destinationAmount,
    bool clearDestinationAmount = false,
    String? mainCurrencyCode,
    double? mainCurrencyAmount,
    bool clearMainCurrencyAmount = false,
    DateTime? date,
    String? note,
    bool clearNote = false,
    String? merchant,
    bool clearMerchant = false,
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
      currencyCode: currencyCode ?? this.currencyCode,
      conversionRate: conversionRate ?? this.conversionRate,
      destinationAmount: clearDestinationAmount
          ? null
          : (destinationAmount ?? this.destinationAmount),
      mainCurrencyCode: mainCurrencyCode ?? this.mainCurrencyCode,
      mainCurrencyAmount: clearMainCurrencyAmount
          ? null
          : (mainCurrencyAmount ?? this.mainCurrencyAmount),
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      merchant: clearMerchant ? null : (merchant ?? this.merchant),
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

  /// Currency-aware net amount converted to main currency.
  double netAmountInMainCurrency(Map<String, double> rates, String mainCurrency) {
    return transactions.fold(0.0, (sum, tx) {
      if (tx.type == TransactionType.transfer) return sum;
      final amount = _convertToMain(tx.amount, tx.currencyCode, mainCurrency, rates);
      return tx.type == TransactionType.income ? sum + amount : sum - amount;
    });
  }

  double totalIncomeInMainCurrency(Map<String, double> rates, String mainCurrency) {
    return transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + _convertToMain(tx.amount, tx.currencyCode, mainCurrency, rates));
  }

  double totalExpenseInMainCurrency(Map<String, double> rates, String mainCurrency) {
    return transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + _convertToMain(tx.amount, tx.currencyCode, mainCurrency, rates));
  }

  static double _convertToMain(double amount, String fromCurrency, String mainCurrency, Map<String, double> rates) {
    if (fromCurrency == mainCurrency) return amount;
    final fromRate = rates[fromCurrency];
    if (fromRate != null && fromRate > 0) {
      return roundCurrency(amount / fromRate);
    }
    return amount;
  }
}
