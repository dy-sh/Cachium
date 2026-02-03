enum PredictionType {
  budgetOverage,
  savingsProjection,
  cashFlowWarning,
  spendingPace,
}

extension PredictionTypeExtension on PredictionType {
  String get displayName {
    switch (this) {
      case PredictionType.budgetOverage:
        return 'Budget Alert';
      case PredictionType.savingsProjection:
        return 'Savings Forecast';
      case PredictionType.cashFlowWarning:
        return 'Cash Flow';
      case PredictionType.spendingPace:
        return 'Spending Pace';
    }
  }
}

enum PredictionSentiment {
  positive,
  warning,
  negative,
}

class PredictionAlert {
  final String id;
  final PredictionType type;
  final PredictionSentiment sentiment;
  final String title;
  final String message;
  final double? projectedAmount;
  final double? targetAmount;
  final DateTime? projectedDate;
  final String? categoryId;
  final String? accountId;

  const PredictionAlert({
    required this.id,
    required this.type,
    required this.sentiment,
    required this.title,
    required this.message,
    this.projectedAmount,
    this.targetAmount,
    this.projectedDate,
    this.categoryId,
    this.accountId,
  });
}
