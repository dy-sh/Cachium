class NetWorthPoint {
  final DateTime date;
  final double totalHoldings;
  final double totalLiabilities;
  final double netWorth;
  final Map<String, double> holdingBalances;
  final Map<String, double> liabilityBalances;

  const NetWorthPoint({
    required this.date,
    required this.totalHoldings,
    required this.totalLiabilities,
    required this.netWorth,
    this.holdingBalances = const {},
    this.liabilityBalances = const {},
  });

  NetWorthPoint copyWith({
    DateTime? date,
    double? totalHoldings,
    double? totalLiabilities,
    double? netWorth,
    Map<String, double>? holdingBalances,
    Map<String, double>? liabilityBalances,
  }) {
    return NetWorthPoint(
      date: date ?? this.date,
      totalHoldings: totalHoldings ?? this.totalHoldings,
      totalLiabilities: totalLiabilities ?? this.totalLiabilities,
      netWorth: netWorth ?? this.netWorth,
      holdingBalances: holdingBalances ?? this.holdingBalances,
      liabilityBalances: liabilityBalances ?? this.liabilityBalances,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetWorthPoint && other.date == date;
  }

  @override
  int get hashCode => date.hashCode;
}
