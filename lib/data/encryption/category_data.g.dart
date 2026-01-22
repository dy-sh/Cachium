// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryDataImpl _$$CategoryDataImplFromJson(Map<String, dynamic> json) =>
    _$CategoryDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: (json['iconCodePoint'] as num).toInt(),
      iconFontFamily: json['iconFontFamily'] as String,
      iconFontPackage: json['iconFontPackage'] as String?,
      colorIndex: (json['colorIndex'] as num).toInt(),
      type: json['type'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
      parentId: json['parentId'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$$CategoryDataImplToJson(_$CategoryDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconCodePoint': instance.iconCodePoint,
      'iconFontFamily': instance.iconFontFamily,
      'iconFontPackage': instance.iconFontPackage,
      'colorIndex': instance.colorIndex,
      'type': instance.type,
      'isCustom': instance.isCustom,
      'parentId': instance.parentId,
      'sortOrder': instance.sortOrder,
    };
