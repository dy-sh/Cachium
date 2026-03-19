import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_data.freezed.dart';
part 'tag_data.g.dart';

/// Internal data model for encrypted tag storage.
@freezed
class TagData with _$TagData {
  const factory TagData({
    /// Tag ID - must match row id for integrity check
    required String id,

    /// Tag name
    required String name,

    /// Index into color palette
    required int colorIndex,

    /// Icon code point
    required int iconCodePoint,

    /// Icon font family
    required String iconFontFamily,

    /// Icon font package, nullable for MaterialIcons
    String? iconFontPackage,

    /// Sort order - duplicated for integrity check
    required int sortOrder,
  }) = _TagData;

  factory TagData.fromJson(Map<String, dynamic> json) =>
      _$TagDataFromJson(json);
}
