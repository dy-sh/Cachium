// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssetDataImpl _$$AssetDataImplFromJson(Map<String, dynamic> json) =>
    _$AssetDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: (json['iconCodePoint'] as num).toInt(),
      iconFontFamily: json['iconFontFamily'] as String?,
      iconFontPackage: json['iconFontPackage'] as String?,
      colorIndex: (json['colorIndex'] as num).toInt(),
      status: json['status'] as String,
      note: json['note'] as String?,
      createdAtMillis: (json['createdAtMillis'] as num).toInt(),
    );

Map<String, dynamic> _$$AssetDataImplToJson(_$AssetDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconCodePoint': instance.iconCodePoint,
      'iconFontFamily': instance.iconFontFamily,
      'iconFontPackage': instance.iconFontPackage,
      'colorIndex': instance.colorIndex,
      'status': instance.status,
      'note': instance.note,
      'createdAtMillis': instance.createdAtMillis,
    };
