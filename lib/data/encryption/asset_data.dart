import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_data.freezed.dart';
part 'asset_data.g.dart';

/// Internal data model for encrypted asset storage.
///
/// This model represents the data that gets serialized to JSON and then
/// encrypted before storing in the database blob. It contains duplicated
/// fields (id, createdAtMillis) for integrity verification during decryption.
@freezed
class AssetData with _$AssetData {
  const factory AssetData({
    /// Duplicated for integrity check - must match row id
    required String id,

    /// Asset name
    required String name,

    /// Icon code point (from IconData)
    required int iconCodePoint,

    /// Icon font family
    String? iconFontFamily,

    /// Icon font package
    String? iconFontPackage,

    /// Color index in accent palette (0-23)
    required int colorIndex,

    /// Asset status: 'active' or 'sold'
    required String status,

    /// Optional description/note
    String? note,

    /// Matches the database createdAt field for integrity verification during import.
    /// Not exported as a separate CSV column to avoid duplication.
    required int createdAtMillis,
  }) = _AssetData;

  factory AssetData.fromJson(Map<String, dynamic> json) =>
      _$AssetDataFromJson(json);
}
