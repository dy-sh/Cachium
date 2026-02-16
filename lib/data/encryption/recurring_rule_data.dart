import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_rule_data.freezed.dart';
part 'recurring_rule_data.g.dart';

/// Internal data model for encrypted recurring rule storage.
@freezed
class RecurringRuleData with _$RecurringRuleData {
  const factory RecurringRuleData({
    required String id,
    required String name,
    required double amount,
    required String type,
    required String categoryId,
    required String accountId,
    String? destinationAccountId,
    String? merchant,
    String? note,
    required String frequency,
    required int startDateMillis,
    int? endDateMillis,
    required int lastGeneratedDateMillis,
    @Default(true) bool isActive,
    required int createdAtMillis,
  }) = _RecurringRuleData;

  factory RecurringRuleData.fromJson(Map<String, dynamic> json) =>
      _$RecurringRuleDataFromJson(json);
}
