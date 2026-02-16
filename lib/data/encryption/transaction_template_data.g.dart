// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_template_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionTemplateDataImpl _$$TransactionTemplateDataImplFromJson(
  Map<String, dynamic> json,
) => _$TransactionTemplateDataImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  amount: (json['amount'] as num?)?.toDouble(),
  type: json['type'] as String,
  categoryId: json['categoryId'] as String?,
  accountId: json['accountId'] as String?,
  destinationAccountId: json['destinationAccountId'] as String?,
  assetId: json['assetId'] as String?,
  merchant: json['merchant'] as String?,
  note: json['note'] as String?,
  createdAtMillis: (json['createdAtMillis'] as num).toInt(),
);

Map<String, dynamic> _$$TransactionTemplateDataImplToJson(
  _$TransactionTemplateDataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'amount': instance.amount,
  'type': instance.type,
  'categoryId': instance.categoryId,
  'accountId': instance.accountId,
  'destinationAccountId': instance.destinationAccountId,
  'assetId': instance.assetId,
  'merchant': instance.merchant,
  'note': instance.note,
  'createdAtMillis': instance.createdAtMillis,
};
