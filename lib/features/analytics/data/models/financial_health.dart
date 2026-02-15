class FinancialHealth {
  final double debtToHoldingRatio;
  final double savingsRate;
  final double emergencyFundMonths;
  final double netWorthTrend;
  final int healthScore;

  const FinancialHealth({
    required this.debtToHoldingRatio,
    required this.savingsRate,
    required this.emergencyFundMonths,
    required this.netWorthTrend,
    required this.healthScore,
  });

  FinancialHealth copyWith({
    double? debtToHoldingRatio,
    double? savingsRate,
    double? emergencyFundMonths,
    double? netWorthTrend,
    int? healthScore,
  }) {
    return FinancialHealth(
      debtToHoldingRatio: debtToHoldingRatio ?? this.debtToHoldingRatio,
      savingsRate: savingsRate ?? this.savingsRate,
      emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
      netWorthTrend: netWorthTrend ?? this.netWorthTrend,
      healthScore: healthScore ?? this.healthScore,
    );
  }

  static const empty = FinancialHealth(
    debtToHoldingRatio: 0,
    savingsRate: 0,
    emergencyFundMonths: 0,
    netWorthTrend: 0,
    healthScore: 0,
  );
}
