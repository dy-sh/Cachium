import 'package:freezed_annotation/freezed_annotation.dart';

part 'savings_goal_data.freezed.dart';
part 'savings_goal_data.g.dart';

/// Internal data model for encrypted savings goal storage.
@freezed
class SavingsGoalData with _$SavingsGoalData {
  const factory SavingsGoalData({
    required String id,
    required String name,
    required double targetAmount,
    @Default(0) double currentAmount,
    required int colorIndex,
    required int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    String? linkedAccountId,
    int? targetDateMillis,
    String? note,
    required int createdAtMillis,
  }) = _SavingsGoalData;

  factory SavingsGoalData.fromJson(Map<String, dynamic> json) =>
      _$SavingsGoalDataFromJson(json);
}
