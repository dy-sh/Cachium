// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_category_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AssetCategoryData _$AssetCategoryDataFromJson(Map<String, dynamic> json) {
  return _AssetCategoryData.fromJson(json);
}

/// @nodoc
mixin _$AssetCategoryData {
  /// Duplicated for integrity check - must match row id
  String get id => throw _privateConstructorUsedError;

  /// Category name
  String get name => throw _privateConstructorUsedError;

  /// Icon code point (from IconData)
  int get iconCodePoint => throw _privateConstructorUsedError;

  /// Icon font family
  String? get iconFontFamily => throw _privateConstructorUsedError;

  /// Icon font package
  String? get iconFontPackage => throw _privateConstructorUsedError;

  /// Color index in accent palette (0-23)
  int get colorIndex => throw _privateConstructorUsedError;

  /// Sort order for display ordering
  int get sortOrder => throw _privateConstructorUsedError;

  /// Matches the database createdAt field for integrity verification.
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this AssetCategoryData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssetCategoryData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetCategoryDataCopyWith<AssetCategoryData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetCategoryDataCopyWith<$Res> {
  factory $AssetCategoryDataCopyWith(
    AssetCategoryData value,
    $Res Function(AssetCategoryData) then,
  ) = _$AssetCategoryDataCopyWithImpl<$Res, AssetCategoryData>;
  @useResult
  $Res call({
    String id,
    String name,
    int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    int colorIndex,
    int sortOrder,
    int createdAtMillis,
  });
}

/// @nodoc
class _$AssetCategoryDataCopyWithImpl<$Res, $Val extends AssetCategoryData>
    implements $AssetCategoryDataCopyWith<$Res> {
  _$AssetCategoryDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssetCategoryData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconCodePoint = null,
    Object? iconFontFamily = freezed,
    Object? iconFontPackage = freezed,
    Object? colorIndex = null,
    Object? sortOrder = null,
    Object? createdAtMillis = null,
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
            iconFontFamily: freezed == iconFontFamily
                ? _value.iconFontFamily
                : iconFontFamily // ignore: cast_nullable_to_non_nullable
                      as String?,
            iconFontPackage: freezed == iconFontPackage
                ? _value.iconFontPackage
                : iconFontPackage // ignore: cast_nullable_to_non_nullable
                      as String?,
            colorIndex: null == colorIndex
                ? _value.colorIndex
                : colorIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAtMillis: null == createdAtMillis
                ? _value.createdAtMillis
                : createdAtMillis // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssetCategoryDataImplCopyWith<$Res>
    implements $AssetCategoryDataCopyWith<$Res> {
  factory _$$AssetCategoryDataImplCopyWith(
    _$AssetCategoryDataImpl value,
    $Res Function(_$AssetCategoryDataImpl) then,
  ) = __$$AssetCategoryDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    int colorIndex,
    int sortOrder,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$AssetCategoryDataImplCopyWithImpl<$Res>
    extends _$AssetCategoryDataCopyWithImpl<$Res, _$AssetCategoryDataImpl>
    implements _$$AssetCategoryDataImplCopyWith<$Res> {
  __$$AssetCategoryDataImplCopyWithImpl(
    _$AssetCategoryDataImpl _value,
    $Res Function(_$AssetCategoryDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssetCategoryData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconCodePoint = null,
    Object? iconFontFamily = freezed,
    Object? iconFontPackage = freezed,
    Object? colorIndex = null,
    Object? sortOrder = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$AssetCategoryDataImpl(
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
        iconFontFamily: freezed == iconFontFamily
            ? _value.iconFontFamily
            : iconFontFamily // ignore: cast_nullable_to_non_nullable
                  as String?,
        iconFontPackage: freezed == iconFontPackage
            ? _value.iconFontPackage
            : iconFontPackage // ignore: cast_nullable_to_non_nullable
                  as String?,
        colorIndex: null == colorIndex
            ? _value.colorIndex
            : colorIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAtMillis: null == createdAtMillis
            ? _value.createdAtMillis
            : createdAtMillis // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetCategoryDataImpl implements _AssetCategoryData {
  const _$AssetCategoryDataImpl({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.colorIndex,
    this.sortOrder = 0,
    required this.createdAtMillis,
  });

  factory _$AssetCategoryDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetCategoryDataImplFromJson(json);

  /// Duplicated for integrity check - must match row id
  @override
  final String id;

  /// Category name
  @override
  final String name;

  /// Icon code point (from IconData)
  @override
  final int iconCodePoint;

  /// Icon font family
  @override
  final String? iconFontFamily;

  /// Icon font package
  @override
  final String? iconFontPackage;

  /// Color index in accent palette (0-23)
  @override
  final int colorIndex;

  /// Sort order for display ordering
  @override
  @JsonKey()
  final int sortOrder;

  /// Matches the database createdAt field for integrity verification.
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'AssetCategoryData(id: $id, name: $name, iconCodePoint: $iconCodePoint, iconFontFamily: $iconFontFamily, iconFontPackage: $iconFontPackage, colorIndex: $colorIndex, sortOrder: $sortOrder, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetCategoryDataImpl &&
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
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAtMillis, createdAtMillis) ||
                other.createdAtMillis == createdAtMillis));
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
    sortOrder,
    createdAtMillis,
  );

  /// Create a copy of AssetCategoryData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetCategoryDataImplCopyWith<_$AssetCategoryDataImpl> get copyWith =>
      __$$AssetCategoryDataImplCopyWithImpl<_$AssetCategoryDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetCategoryDataImplToJson(this);
  }
}

abstract class _AssetCategoryData implements AssetCategoryData {
  const factory _AssetCategoryData({
    required final String id,
    required final String name,
    required final int iconCodePoint,
    final String? iconFontFamily,
    final String? iconFontPackage,
    required final int colorIndex,
    final int sortOrder,
    required final int createdAtMillis,
  }) = _$AssetCategoryDataImpl;

  factory _AssetCategoryData.fromJson(Map<String, dynamic> json) =
      _$AssetCategoryDataImpl.fromJson;

  /// Duplicated for integrity check - must match row id
  @override
  String get id;

  /// Category name
  @override
  String get name;

  /// Icon code point (from IconData)
  @override
  int get iconCodePoint;

  /// Icon font family
  @override
  String? get iconFontFamily;

  /// Icon font package
  @override
  String? get iconFontPackage;

  /// Color index in accent palette (0-23)
  @override
  int get colorIndex;

  /// Sort order for display ordering
  @override
  int get sortOrder;

  /// Matches the database createdAt field for integrity verification.
  @override
  int get createdAtMillis;

  /// Create a copy of AssetCategoryData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetCategoryDataImplCopyWith<_$AssetCategoryDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
