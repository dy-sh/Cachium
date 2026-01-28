class ForecastProjection {
  final DateTime date;
  final double amount;
  final double upperBound;
  final double lowerBound;
  final bool isActual;

  const ForecastProjection({
    required this.date,
    required this.amount,
    required this.upperBound,
    required this.lowerBound,
    required this.isActual,
  });

  ForecastProjection copyWith({
    DateTime? date,
    double? amount,
    double? upperBound,
    double? lowerBound,
    bool? isActual,
  }) {
    return ForecastProjection(
      date: date ?? this.date,
      amount: amount ?? this.amount,
      upperBound: upperBound ?? this.upperBound,
      lowerBound: lowerBound ?? this.lowerBound,
      isActual: isActual ?? this.isActual,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForecastProjection &&
        other.date == date &&
        other.isActual == isActual;
  }

  @override
  int get hashCode => Object.hash(date, isActual);
}
