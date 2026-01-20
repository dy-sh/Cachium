// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountDataImpl _$$AccountDataImplFromJson(Map<String, dynamic> json) =>
    _$AccountDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble(),
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      customColorValue: (json['customColorValue'] as num?)?.toInt(),
      customIconCodePoint: (json['customIconCodePoint'] as num?)?.toInt(),
      createdAtMillis: (json['createdAtMillis'] as num).toInt(),
    );

Map<String, dynamic> _$$AccountDataImplToJson(_$AccountDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'balance': instance.balance,
      'initialBalance': instance.initialBalance,
      'customColorValue': instance.customColorValue,
      'customIconCodePoint': instance.customIconCodePoint,
      'createdAtMillis': instance.createdAtMillis,
    };
