// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_goal_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SavingsGoalDataImpl _$$SavingsGoalDataImplFromJson(
  Map<String, dynamic> json,
) => _$SavingsGoalDataImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  targetAmount: (json['targetAmount'] as num).toDouble(),
  currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
  colorIndex: (json['colorIndex'] as num).toInt(),
  iconCodePoint: (json['iconCodePoint'] as num).toInt(),
  iconFontFamily: json['iconFontFamily'] as String?,
  iconFontPackage: json['iconFontPackage'] as String?,
  linkedAccountId: json['linkedAccountId'] as String?,
  targetDateMillis: (json['targetDateMillis'] as num?)?.toInt(),
  note: json['note'] as String?,
  createdAtMillis: (json['createdAtMillis'] as num).toInt(),
);

Map<String, dynamic> _$$SavingsGoalDataImplToJson(
  _$SavingsGoalDataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'targetAmount': instance.targetAmount,
  'currentAmount': instance.currentAmount,
  'colorIndex': instance.colorIndex,
  'iconCodePoint': instance.iconCodePoint,
  'iconFontFamily': instance.iconFontFamily,
  'iconFontPackage': instance.iconFontPackage,
  'linkedAccountId': instance.linkedAccountId,
  'targetDateMillis': instance.targetDateMillis,
  'note': instance.note,
  'createdAtMillis': instance.createdAtMillis,
};
