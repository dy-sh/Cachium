// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionDataImpl _$$TransactionDataImplFromJson(
  Map<String, dynamic> json,
) => _$TransactionDataImpl(
  id: json['id'] as String,
  amount: (json['amount'] as num).toDouble(),
  categoryId: json['categoryId'] as String,
  accountId: json['accountId'] as String,
  type: json['type'] as String,
  note: json['note'] as String?,
  merchant: json['merchant'] as String?,
  destinationAccountId: json['destinationAccountId'] as String?,
  assetId: json['assetId'] as String?,
  isAcquisitionCost: json['isAcquisitionCost'] as bool? ?? false,
  currency: json['currency'] as String? ?? 'USD',
  conversionRate: (json['conversionRate'] as num?)?.toDouble() ?? 1.0,
  destinationAmount: (json['destinationAmount'] as num?)?.toDouble(),
  mainCurrencyCode: json['mainCurrencyCode'] as String? ?? 'USD',
  mainCurrencyAmount: (json['mainCurrencyAmount'] as num?)?.toDouble(),
  dateMillis: (json['dateMillis'] as num).toInt(),
  createdAtMillis: (json['createdAtMillis'] as num).toInt(),
);

Map<String, dynamic> _$$TransactionDataImplToJson(
  _$TransactionDataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'amount': instance.amount,
  'categoryId': instance.categoryId,
  'accountId': instance.accountId,
  'type': instance.type,
  'note': instance.note,
  'merchant': instance.merchant,
  'destinationAccountId': instance.destinationAccountId,
  'assetId': instance.assetId,
  'isAcquisitionCost': instance.isAcquisitionCost,
  'currency': instance.currency,
  'conversionRate': instance.conversionRate,
  'destinationAmount': instance.destinationAmount,
  'mainCurrencyCode': instance.mainCurrencyCode,
  'mainCurrencyAmount': instance.mainCurrencyAmount,
  'dateMillis': instance.dateMillis,
  'createdAtMillis': instance.createdAtMillis,
};
