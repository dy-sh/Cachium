import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_template_data.freezed.dart';
part 'transaction_template_data.g.dart';

@freezed
class TransactionTemplateData with _$TransactionTemplateData {
  const factory TransactionTemplateData({
    required String id,
    required String name,
    double? amount,
    required String type,
    String? categoryId,
    String? accountId,
    String? destinationAccountId,
    String? assetId,
    String? merchant,
    String? note,
    required int createdAtMillis,
  }) = _TransactionTemplateData;

  factory TransactionTemplateData.fromJson(Map<String, dynamic> json) =>
      _$TransactionTemplateDataFromJson(json);
}
