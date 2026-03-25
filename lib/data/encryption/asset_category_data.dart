import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_category_data.freezed.dart';
part 'asset_category_data.g.dart';

/// Internal data model for encrypted asset category storage.
@freezed
class AssetCategoryData with _$AssetCategoryData {
  const factory AssetCategoryData({
    /// Duplicated for integrity check - must match row id
    required String id,

    /// Category name
    required String name,

    /// Icon code point (from IconData)
    required int iconCodePoint,

    /// Icon font family
    String? iconFontFamily,

    /// Icon font package
    String? iconFontPackage,

    /// Color index in accent palette (0-23)
    required int colorIndex,

    /// Sort order for display ordering
    @Default(0) int sortOrder,

    /// Matches the database createdAt field for integrity verification.
    required int createdAtMillis,
  }) = _AssetCategoryData;

  factory AssetCategoryData.fromJson(Map<String, dynamic> json) =>
      _$AssetCategoryDataFromJson(json);
}
