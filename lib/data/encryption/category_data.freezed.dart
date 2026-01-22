// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CategoryData _$CategoryDataFromJson(Map<String, dynamic> json) {
  return _CategoryData.fromJson(json);
}

/// @nodoc
mixin _$CategoryData {
  /// Category ID - must match row id for integrity check
  String get id => throw _privateConstructorUsedError;

  /// Category name
  String get name => throw _privateConstructorUsedError;

  /// Icon code point (e.g., 0xe000)
  int get iconCodePoint => throw _privateConstructorUsedError;

  /// Icon font family (e.g., 'lucide')
  String get iconFontFamily => throw _privateConstructorUsedError;

  /// Icon font package (e.g., 'lucide_icons'), nullable for MaterialIcons
  String? get iconFontPackage => throw _privateConstructorUsedError;

  /// Index into category color palette
  int get colorIndex => throw _privateConstructorUsedError;

  /// Category type: 'income' or 'expense'
  String get type => throw _privateConstructorUsedError;

  /// Whether this is a user-created category
  bool get isCustom => throw _privateConstructorUsedError;

  /// Parent category ID for nested categories
  String? get parentId => throw _privateConstructorUsedError;

  /// Sort order within the same parent - duplicated for integrity check
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this CategoryData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CategoryData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryDataCopyWith<CategoryData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryDataCopyWith<$Res> {
  factory $CategoryDataCopyWith(
    CategoryData value,
    $Res Function(CategoryData) then,
  ) = _$CategoryDataCopyWithImpl<$Res, CategoryData>;
  @useResult
  $Res call({
    String id,
    String name,
    int iconCodePoint,
    String iconFontFamily,
    String? iconFontPackage,
    int colorIndex,
    String type,
    bool isCustom,
    String? parentId,
    int sortOrder,
  });
}

/// @nodoc
class _$CategoryDataCopyWithImpl<$Res, $Val extends CategoryData>
    implements $CategoryDataCopyWith<$Res> {
  _$CategoryDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconCodePoint = null,
    Object? iconFontFamily = null,
    Object? iconFontPackage = freezed,
    Object? colorIndex = null,
    Object? type = null,
    Object? isCustom = null,
    Object? parentId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            iconCodePoint: null == iconCodePoint
                ? _value.iconCodePoint
                : iconCodePoint // ignore: cast_nullable_to_non_nullable
                      as int,
            iconFontFamily: null == iconFontFamily
                ? _value.iconFontFamily
                : iconFontFamily // ignore: cast_nullable_to_non_nullable
                      as String,
            iconFontPackage: freezed == iconFontPackage
                ? _value.iconFontPackage
                : iconFontPackage // ignore: cast_nullable_to_non_nullable
                      as String?,
            colorIndex: null == colorIndex
                ? _value.colorIndex
                : colorIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            isCustom: null == isCustom
                ? _value.isCustom
                : isCustom // ignore: cast_nullable_to_non_nullable
                      as bool,
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryDataImplCopyWith<$Res>
    implements $CategoryDataCopyWith<$Res> {
  factory _$$CategoryDataImplCopyWith(
    _$CategoryDataImpl value,
    $Res Function(_$CategoryDataImpl) then,
  ) = __$$CategoryDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int iconCodePoint,
    String iconFontFamily,
    String? iconFontPackage,
    int colorIndex,
    String type,
    bool isCustom,
    String? parentId,
    int sortOrder,
  });
}

/// @nodoc
class __$$CategoryDataImplCopyWithImpl<$Res>
    extends _$CategoryDataCopyWithImpl<$Res, _$CategoryDataImpl>
    implements _$$CategoryDataImplCopyWith<$Res> {
  __$$CategoryDataImplCopyWithImpl(
    _$CategoryDataImpl _value,
    $Res Function(_$CategoryDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CategoryData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconCodePoint = null,
    Object? iconFontFamily = null,
    Object? iconFontPackage = freezed,
    Object? colorIndex = null,
    Object? type = null,
    Object? isCustom = null,
    Object? parentId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(
      _$CategoryDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        iconCodePoint: null == iconCodePoint
            ? _value.iconCodePoint
            : iconCodePoint // ignore: cast_nullable_to_non_nullable
                  as int,
        iconFontFamily: null == iconFontFamily
            ? _value.iconFontFamily
            : iconFontFamily // ignore: cast_nullable_to_non_nullable
                  as String,
        iconFontPackage: freezed == iconFontPackage
            ? _value.iconFontPackage
            : iconFontPackage // ignore: cast_nullable_to_non_nullable
                  as String?,
        colorIndex: null == colorIndex
            ? _value.colorIndex
            : colorIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        isCustom: null == isCustom
            ? _value.isCustom
            : isCustom // ignore: cast_nullable_to_non_nullable
                  as bool,
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryDataImpl implements _CategoryData {
  const _$CategoryDataImpl({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    this.iconFontPackage,
    required this.colorIndex,
    required this.type,
    this.isCustom = false,
    this.parentId,
    required this.sortOrder,
  });

  factory _$CategoryDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryDataImplFromJson(json);

  /// Category ID - must match row id for integrity check
  @override
  final String id;

  /// Category name
  @override
  final String name;

  /// Icon code point (e.g., 0xe000)
  @override
  final int iconCodePoint;

  /// Icon font family (e.g., 'lucide')
  @override
  final String iconFontFamily;

  /// Icon font package (e.g., 'lucide_icons'), nullable for MaterialIcons
  @override
  final String? iconFontPackage;

  /// Index into category color palette
  @override
  final int colorIndex;

  /// Category type: 'income' or 'expense'
  @override
  final String type;

  /// Whether this is a user-created category
  @override
  @JsonKey()
  final bool isCustom;

  /// Parent category ID for nested categories
  @override
  final String? parentId;

  /// Sort order within the same parent - duplicated for integrity check
  @override
  final int sortOrder;

  @override
  String toString() {
    return 'CategoryData(id: $id, name: $name, iconCodePoint: $iconCodePoint, iconFontFamily: $iconFontFamily, iconFontPackage: $iconFontPackage, colorIndex: $colorIndex, type: $type, isCustom: $isCustom, parentId: $parentId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.iconCodePoint, iconCodePoint) ||
                other.iconCodePoint == iconCodePoint) &&
            (identical(other.iconFontFamily, iconFontFamily) ||
                other.iconFontFamily == iconFontFamily) &&
            (identical(other.iconFontPackage, iconFontPackage) ||
                other.iconFontPackage == iconFontPackage) &&
            (identical(other.colorIndex, colorIndex) ||
                other.colorIndex == colorIndex) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isCustom, isCustom) ||
                other.isCustom == isCustom) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    iconCodePoint,
    iconFontFamily,
    iconFontPackage,
    colorIndex,
    type,
    isCustom,
    parentId,
    sortOrder,
  );

  /// Create a copy of CategoryData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryDataImplCopyWith<_$CategoryDataImpl> get copyWith =>
      __$$CategoryDataImplCopyWithImpl<_$CategoryDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryDataImplToJson(this);
  }
}

abstract class _CategoryData implements CategoryData {
  const factory _CategoryData({
    required final String id,
    required final String name,
    required final int iconCodePoint,
    required final String iconFontFamily,
    final String? iconFontPackage,
    required final int colorIndex,
    required final String type,
    final bool isCustom,
    final String? parentId,
    required final int sortOrder,
  }) = _$CategoryDataImpl;

  factory _CategoryData.fromJson(Map<String, dynamic> json) =
      _$CategoryDataImpl.fromJson;

  /// Category ID - must match row id for integrity check
  @override
  String get id;

  /// Category name
  @override
  String get name;

  /// Icon code point (e.g., 0xe000)
  @override
  int get iconCodePoint;

  /// Icon font family (e.g., 'lucide')
  @override
  String get iconFontFamily;

  /// Icon font package (e.g., 'lucide_icons'), nullable for MaterialIcons
  @override
  String? get iconFontPackage;

  /// Index into category color palette
  @override
  int get colorIndex;

  /// Category type: 'income' or 'expense'
  @override
  String get type;

  /// Whether this is a user-created category
  @override
  bool get isCustom;

  /// Parent category ID for nested categories
  @override
  String? get parentId;

  /// Sort order within the same parent - duplicated for integrity check
  @override
  int get sortOrder;

  /// Create a copy of CategoryData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryDataImplCopyWith<_$CategoryDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
