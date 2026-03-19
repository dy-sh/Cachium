class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final int year;
  final int month;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.year,
    required this.month,
    required this.createdAt,
  })  : assert(amount >= 0, 'Budget amount must be non-negative'),
        assert(month >= 1 && month <= 12, 'Month must be between 1 and 12'),
        assert(year >= 2000 && year <= 2100,
            'Year must be between 2000 and 2100');

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    int? year,
    int? month,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
