class CategoryTimeSeries {
  final String categoryId;
  final String name;
  final int colorIndex;
  final List<TimeSeriesPoint> points;

  const CategoryTimeSeries({
    required this.categoryId,
    required this.name,
    required this.colorIndex,
    required this.points,
  });

  double get total => points.fold(0, (s, p) => s + p.amount);
}

class TimeSeriesPoint {
  final DateTime date;
  final String label;
  final double amount;

  const TimeSeriesPoint({
    required this.date,
    required this.label,
    required this.amount,
  });
}
