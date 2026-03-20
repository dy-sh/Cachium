class NetWorthSnapshot {
  final String id;
  final DateTime date; // First of month
  final double netWorth;
  final double totalHoldings;
  final double totalLiabilities;
  final Map<String, double> perAccountBalances;
  final String mainCurrencyCode;

  const NetWorthSnapshot({
    required this.id,
    required this.date,
    required this.netWorth,
    required this.totalHoldings,
    required this.totalLiabilities,
    this.perAccountBalances = const {},
    required this.mainCurrencyCode,
  });

  NetWorthSnapshot copyWith({
    String? id,
    DateTime? date,
    double? netWorth,
    double? totalHoldings,
    double? totalLiabilities,
    Map<String, double>? perAccountBalances,
    String? mainCurrencyCode,
  }) {
    return NetWorthSnapshot(
      id: id ?? this.id,
      date: date ?? this.date,
      netWorth: netWorth ?? this.netWorth,
      totalHoldings: totalHoldings ?? this.totalHoldings,
      totalLiabilities: totalLiabilities ?? this.totalLiabilities,
      perAccountBalances: perAccountBalances ?? this.perAccountBalances,
      mainCurrencyCode: mainCurrencyCode ?? this.mainCurrencyCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetWorthSnapshot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
