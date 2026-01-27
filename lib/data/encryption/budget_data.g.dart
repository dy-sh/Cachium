// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BudgetDataImpl _$$BudgetDataImplFromJson(Map<String, dynamic> json) =>
    _$BudgetDataImpl(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      createdAtMillis: (json['createdAtMillis'] as num).toInt(),
    );

Map<String, dynamic> _$$BudgetDataImplToJson(_$BudgetDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'amount': instance.amount,
      'year': instance.year,
      'month': instance.month,
      'createdAtMillis': instance.createdAtMillis,
    };
