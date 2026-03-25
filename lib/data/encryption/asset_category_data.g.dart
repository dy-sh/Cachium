// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_category_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssetCategoryDataImpl _$$AssetCategoryDataImplFromJson(
  Map<String, dynamic> json,
) => _$AssetCategoryDataImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  iconCodePoint: (json['iconCodePoint'] as num).toInt(),
  iconFontFamily: json['iconFontFamily'] as String?,
  iconFontPackage: json['iconFontPackage'] as String?,
  colorIndex: (json['colorIndex'] as num).toInt(),
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  createdAtMillis: (json['createdAtMillis'] as num).toInt(),
);

Map<String, dynamic> _$$AssetCategoryDataImplToJson(
  _$AssetCategoryDataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'iconCodePoint': instance.iconCodePoint,
  'iconFontFamily': instance.iconFontFamily,
  'iconFontPackage': instance.iconFontPackage,
  'colorIndex': instance.colorIndex,
  'sortOrder': instance.sortOrder,
  'createdAtMillis': instance.createdAtMillis,
};
