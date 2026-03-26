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
      soldDateMillis: (json['soldDateMillis'] as num?)?.toInt(),
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      saleCurrencyCode: json['saleCurrencyCode'] as String?,
      note: json['note'] as String?,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      purchaseCurrencyCode: json['purchaseCurrencyCode'] as String?,
      assetCategoryId: json['assetCategoryId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
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
      'soldDateMillis': instance.soldDateMillis,
      'salePrice': instance.salePrice,
      'saleCurrencyCode': instance.saleCurrencyCode,
      'note': instance.note,
      'purchasePrice': instance.purchasePrice,
      'purchaseCurrencyCode': instance.purchaseCurrencyCode,
      'assetCategoryId': instance.assetCategoryId,
      'sortOrder': instance.sortOrder,
      'createdAtMillis': instance.createdAtMillis,
    };
