import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/spending_anomaly.dart';
import 'package:cachium/features/analytics/data/models/prediction_alert.dart';

void main() {
  group('AnomalyType.displayName', () {
    test('returns correct values', () {
      expect(AnomalyType.unusualTransaction.displayName, 'Unusual Transaction');
      expect(AnomalyType.spendingSpike.displayName, 'Spending Spike');
      expect(AnomalyType.categoryOverspend.displayName, 'Category Overspend');
      expect(AnomalyType.merchantSpike.displayName, 'Merchant Spike');
    });
  });

  group('PredictionType.displayName', () {
    test('returns correct values', () {
      expect(PredictionType.budgetOverage.displayName, 'Budget Alert');
      expect(PredictionType.savingsProjection.displayName, 'Savings Forecast');
      expect(PredictionType.cashFlowWarning.displayName, 'Cash Flow');
      expect(PredictionType.spendingPace.displayName, 'Spending Pace');
    });
  });
}
