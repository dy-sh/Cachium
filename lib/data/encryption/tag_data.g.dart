// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TagDataImpl _$$TagDataImplFromJson(Map<String, dynamic> json) =>
    _$TagDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      colorIndex: (json['colorIndex'] as num).toInt(),
      iconCodePoint: (json['iconCodePoint'] as num).toInt(),
      iconFontFamily: json['iconFontFamily'] as String,
      iconFontPackage: json['iconFontPackage'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$$TagDataImplToJson(_$TagDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorIndex': instance.colorIndex,
      'iconCodePoint': instance.iconCodePoint,
      'iconFontFamily': instance.iconFontFamily,
      'iconFontPackage': instance.iconFontPackage,
      'sortOrder': instance.sortOrder,
    };
