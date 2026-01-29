class FinancialHealth {
  final double debtToAssetRatio;
  final double savingsRate;
  final double emergencyFundMonths;
  final double netWorthTrend;
  final int healthScore;

  const FinancialHealth({
    required this.debtToAssetRatio,
    required this.savingsRate,
    required this.emergencyFundMonths,
    required this.netWorthTrend,
    required this.healthScore,
  });

  FinancialHealth copyWith({
    double? debtToAssetRatio,
    double? savingsRate,
    double? emergencyFundMonths,
    double? netWorthTrend,
    int? healthScore,
  }) {
    return FinancialHealth(
      debtToAssetRatio: debtToAssetRatio ?? this.debtToAssetRatio,
      savingsRate: savingsRate ?? this.savingsRate,
      emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
      netWorthTrend: netWorthTrend ?? this.netWorthTrend,
      healthScore: healthScore ?? this.healthScore,
    );
  }

  static const empty = FinancialHealth(
    debtToAssetRatio: 0,
    savingsRate: 0,
    emergencyFundMonths: 0,
    netWorthTrend: 0,
    healthScore: 0,
  );
}
