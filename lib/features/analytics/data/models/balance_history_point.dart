class BalanceHistoryPoint {
  final DateTime date;
  final double totalBalance;
  final Map<String, double> accountBalances;

  const BalanceHistoryPoint({
    required this.date,
    required this.totalBalance,
    this.accountBalances = const {},
  });

  BalanceHistoryPoint copyWith({
    DateTime? date,
    double? totalBalance,
    Map<String, double>? accountBalances,
  }) {
    return BalanceHistoryPoint(
      date: date ?? this.date,
      totalBalance: totalBalance ?? this.totalBalance,
      accountBalances: accountBalances ?? this.accountBalances,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BalanceHistoryPoint && other.date == date;
  }

  @override
  int get hashCode => date.hashCode;
}
