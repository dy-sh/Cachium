// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecurringRuleDataImpl _$$RecurringRuleDataImplFromJson(
  Map<String, dynamic> json,
) => _$RecurringRuleDataImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  amount: (json['amount'] as num).toDouble(),
  type: json['type'] as String,
  categoryId: json['categoryId'] as String,
  accountId: json['accountId'] as String,
  destinationAccountId: json['destinationAccountId'] as String?,
  merchant: json['merchant'] as String?,
  note: json['note'] as String?,
  frequency: json['frequency'] as String,
  startDateMillis: (json['startDateMillis'] as num).toInt(),
  endDateMillis: (json['endDateMillis'] as num?)?.toInt(),
  lastGeneratedDateMillis: (json['lastGeneratedDateMillis'] as num).toInt(),
  isActive: json['isActive'] as bool? ?? true,
  createdAtMillis: (json['createdAtMillis'] as num).toInt(),
);

Map<String, dynamic> _$$RecurringRuleDataImplToJson(
  _$RecurringRuleDataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'amount': instance.amount,
  'type': instance.type,
  'categoryId': instance.categoryId,
  'accountId': instance.accountId,
  'destinationAccountId': instance.destinationAccountId,
  'merchant': instance.merchant,
  'note': instance.note,
  'frequency': instance.frequency,
  'startDateMillis': instance.startDateMillis,
  'endDateMillis': instance.endDateMillis,
  'lastGeneratedDateMillis': instance.lastGeneratedDateMillis,
  'isActive': instance.isActive,
  'createdAtMillis': instance.createdAtMillis,
};
