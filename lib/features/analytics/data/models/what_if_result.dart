class WhatIfAdjustment {
  final String categoryId;
  final String categoryName;
  final double percentChange;

  const WhatIfAdjustment({
    required this.categoryId,
    required this.categoryName,
    required this.percentChange,
  });

  WhatIfAdjustment copyWith({
    String? categoryId,
    String? categoryName,
    double? percentChange,
  }) {
    return WhatIfAdjustment(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      percentChange: percentChange ?? this.percentChange,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatIfAdjustment && other.categoryId == categoryId;
  }

  @override
  int get hashCode => categoryId.hashCode;
}

class WhatIfResult {
  final double baselineMonthlyNet;
  final double projectedMonthlyNet;
  final double baselineMonthlyExpense;
  final double projectedMonthlyExpense;
  final double baselineMonthlyIncome;
  final List<WhatIfCategoryImpact> categoryImpacts;

  const WhatIfResult({
    required this.baselineMonthlyNet,
    required this.projectedMonthlyNet,
    required this.baselineMonthlyExpense,
    required this.projectedMonthlyExpense,
    required this.baselineMonthlyIncome,
    required this.categoryImpacts,
  });

  double get netChange => projectedMonthlyNet - baselineMonthlyNet;

  double get netChangePercent =>
      baselineMonthlyNet != 0
          ? (netChange / baselineMonthlyNet.abs() * 100)
          : 0;
}

class WhatIfCategoryImpact {
  final String categoryId;
  final String categoryName;
  final double originalAmount;
  final double adjustedAmount;
  final double percentChange;

  const WhatIfCategoryImpact({
    required this.categoryId,
    required this.categoryName,
    required this.originalAmount,
    required this.adjustedAmount,
    required this.percentChange,
  });

  double get amountChange => adjustedAmount - originalAmount;
}
