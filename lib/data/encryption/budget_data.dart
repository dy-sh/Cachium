import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_data.freezed.dart';
part 'budget_data.g.dart';

@freezed
class BudgetData with _$BudgetData {
  const factory BudgetData({
    required String id,
    required String categoryId,
    required double amount,
    required int year,
    required int month,
    required int createdAtMillis,
  }) = _BudgetData;

  factory BudgetData.fromJson(Map<String, dynamic> json) =>
      _$BudgetDataFromJson(json);
}
