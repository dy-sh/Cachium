import '../../../transactions/data/models/transaction.dart';

enum AnomalyType {
  unusualTransaction,
  spendingSpike,
  categoryOverspend,
  merchantSpike,
}

extension AnomalyTypeExtension on AnomalyType {
  String get displayName {
    switch (this) {
      case AnomalyType.unusualTransaction:
        return 'Unusual Transaction';
      case AnomalyType.spendingSpike:
        return 'Spending Spike';
      case AnomalyType.categoryOverspend:
        return 'Category Overspend';
      case AnomalyType.merchantSpike:
        return 'Merchant Spike';
    }
  }
}

enum AnomalySeverity {
  high,
  medium,
  low,
}

class SpendingAnomaly {
  final String id;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String message;
  final String? categoryId;
  final String? merchant;
  final Transaction? transaction;
  final double? amount;
  final double? averageAmount;
  final double? percentageAboveAverage;
  final DateTime detectedAt;

  const SpendingAnomaly({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    this.categoryId,
    this.merchant,
    this.transaction,
    this.amount,
    this.averageAmount,
    this.percentageAboveAverage,
    required this.detectedAt,
  });
}
