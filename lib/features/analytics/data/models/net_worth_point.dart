class NetWorthPoint {
  final DateTime date;
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final Map<String, double> assetBalances;
  final Map<String, double> liabilityBalances;

  const NetWorthPoint({
    required this.date,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    this.assetBalances = const {},
    this.liabilityBalances = const {},
  });

  NetWorthPoint copyWith({
    DateTime? date,
    double? totalAssets,
    double? totalLiabilities,
    double? netWorth,
    Map<String, double>? assetBalances,
    Map<String, double>? liabilityBalances,
  }) {
    return NetWorthPoint(
      date: date ?? this.date,
      totalAssets: totalAssets ?? this.totalAssets,
      totalLiabilities: totalLiabilities ?? this.totalLiabilities,
      netWorth: netWorth ?? this.netWorth,
      assetBalances: assetBalances ?? this.assetBalances,
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
