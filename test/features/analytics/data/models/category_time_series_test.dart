import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/category_time_series.dart';

void main() {
  group('CategoryTimeSeries.total', () {
    test('sums all point amounts', () {
      final series = CategoryTimeSeries(
        categoryId: 'cat-1',
        name: 'Food',
        colorIndex: 0,
        points: [
          TimeSeriesPoint(date: DateTime(2026, 1, 1), label: 'Jan', amount: 100),
          TimeSeriesPoint(date: DateTime(2026, 2, 1), label: 'Feb', amount: 200),
          TimeSeriesPoint(date: DateTime(2026, 3, 1), label: 'Mar', amount: 150),
        ],
      );
      expect(series.total, 450);
    });

    test('returns 0 for empty points', () {
      const series = CategoryTimeSeries(
        categoryId: 'cat-1',
        name: 'Food',
        colorIndex: 0,
        points: [],
      );
      expect(series.total, 0);
    });

    test('handles single point', () {
      final series = CategoryTimeSeries(
        categoryId: 'cat-1',
        name: 'Food',
        colorIndex: 0,
        points: [
          TimeSeriesPoint(date: DateTime(2026, 1, 1), label: 'Jan', amount: 500),
        ],
      );
      expect(series.total, 500);
    });
  });
}
