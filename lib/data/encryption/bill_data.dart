import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill_data.freezed.dart';
part 'bill_data.g.dart';

/// Internal data model for encrypted bill storage.
@freezed
class BillData with _$BillData {
  const factory BillData({
    required String id,
    required String name,
    required double amount,
    @Default('USD') String currencyCode,
    String? categoryId,
    String? accountId,
    String? assetId,
    required int dueDateMillis,
    required String frequency,
    @Default(false) bool isPaid,
    int? paidDateMillis,
    String? note,
    @Default(true) bool reminderEnabled,
    @Default(3) int reminderDaysBefore,
    required int createdAtMillis,
  }) = _BillData;

  factory BillData.fromJson(Map<String, dynamic> json) =>
      _$BillDataFromJson(json);
}
