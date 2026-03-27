import '../../../../core/exceptions/app_exception.dart';

class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final int year;
  final int month;
  final bool rolloverEnabled;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.year,
    required this.month,
    this.rolloverEnabled = false,
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
    bool? rolloverEnabled,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  void validate() {
    if (id.isEmpty) {
      throw const ValidationException(
          message: 'Budget ID must not be empty', field: 'id');
    }
    if (categoryId.isEmpty) {
      throw const ValidationException(
          message: 'Category ID must not be empty', field: 'categoryId');
    }
    if (amount < 0) {
      throw const ValidationException(
          message: 'Budget amount must be non-negative', field: 'amount');
    }
    if (year < 2000 || year > 2100) {
      throw const ValidationException(
          message: 'Year must be between 2000 and 2100', field: 'year');
    }
    if (month < 1 || month > 12) {
      throw const ValidationException(
          message: 'Month must be between 1 and 12', field: 'month');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
