import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_data.freezed.dart';
part 'category_data.g.dart';

/// Internal data model for encrypted category storage.
///
/// This model represents the data that gets serialized to JSON and then
/// encrypted before storing in the database blob. It contains the category ID
/// for integrity verification during decryption.
@freezed
class CategoryData with _$CategoryData {
  const factory CategoryData({
    /// Category ID - must match row id for integrity check
    required String id,

    /// Category name
    required String name,

    /// Icon code point (e.g., 0xe000)
    required int iconCodePoint,

    /// Icon font family (e.g., 'lucide')
    required String iconFontFamily,

    /// Icon font package (e.g., 'lucide_icons'), nullable for MaterialIcons
    String? iconFontPackage,

    /// Index into category color palette
    required int colorIndex,

    /// Category type: 'income' or 'expense'
    required String type,

    /// Whether this is a user-created category
    @Default(false) bool isCustom,

    /// Parent category ID for nested categories
    String? parentId,

    /// Sort order within the same parent - duplicated for integrity check
    required int sortOrder,
  }) = _CategoryData;

  factory CategoryData.fromJson(Map<String, dynamic> json) =>
      _$CategoryDataFromJson(json);
}
