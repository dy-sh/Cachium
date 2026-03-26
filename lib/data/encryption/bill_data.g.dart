// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BillDataImpl _$$BillDataImplFromJson(Map<String, dynamic> json) =>
    _$BillDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      categoryId: json['categoryId'] as String?,
      accountId: json['accountId'] as String?,
      assetId: json['assetId'] as String?,
      dueDateMillis: (json['dueDateMillis'] as num).toInt(),
      frequency: json['frequency'] as String,
      isPaid: json['isPaid'] as bool? ?? false,
      paidDateMillis: (json['paidDateMillis'] as num?)?.toInt(),
      note: json['note'] as String?,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      reminderDaysBefore: (json['reminderDaysBefore'] as num?)?.toInt() ?? 3,
      createdAtMillis: (json['createdAtMillis'] as num).toInt(),
    );

Map<String, dynamic> _$$BillDataImplToJson(_$BillDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'currencyCode': instance.currencyCode,
      'categoryId': instance.categoryId,
      'accountId': instance.accountId,
      'assetId': instance.assetId,
      'dueDateMillis': instance.dueDateMillis,
      'frequency': instance.frequency,
      'isPaid': instance.isPaid,
      'paidDateMillis': instance.paidDateMillis,
      'note': instance.note,
      'reminderEnabled': instance.reminderEnabled,
      'reminderDaysBefore': instance.reminderDaysBefore,
      'createdAtMillis': instance.createdAtMillis,
    };
