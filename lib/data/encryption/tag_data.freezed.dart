// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TagData _$TagDataFromJson(Map<String, dynamic> json) {
  return _TagData.fromJson(json);
}

/// @nodoc
mixin _$TagData {
  /// Tag ID - must match row id for integrity check
  String get id => throw _privateConstructorUsedError;

  /// Tag name
  String get name => throw _privateConstructorUsedError;

  /// Index into color palette
  int get colorIndex => throw _privateConstructorUsedError;

  /// Icon code point
  int get iconCodePoint => throw _privateConstructorUsedError;

  /// Icon font family
  String get iconFontFamily => throw _privateConstructorUsedError;

  /// Icon font package, nullable for MaterialIcons
  String? get iconFontPackage => throw _privateConstructorUsedError;

  /// Sort order - duplicated for integrity check
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this TagData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TagData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TagDataCopyWith<TagData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TagDataCopyWith<$Res> {
  factory $TagDataCopyWith(TagData value, $Res Function(TagData) then) =
      _$TagDataCopyWithImpl<$Res, TagData>;
  @useResult
  $Res call({
    String id,
    String name,
    int colorIndex,
    int iconCodePoint,
    String iconFontFamily,
    String? iconFontPackage,
    int sortOrder,
  });
}

/// @nodoc
class _$TagDataCopyWithImpl<$Res, $Val extends TagData>
    implements $TagDataCopyWith<$Res> {
  _$TagDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TagData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? colorIndex = null,
    Object? iconCodePoint = null,
    Object? iconFontFamily = null,
    Object? iconFontPackage = freezed,
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
            colorIndex: null == colorIndex
                ? _value.colorIndex
                : colorIndex // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$TagDataImplCopyWith<$Res> implements $TagDataCopyWith<$Res> {
  factory _$$TagDataImplCopyWith(
    _$TagDataImpl value,
    $Res Function(_$TagDataImpl) then,
  ) = __$$TagDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int colorIndex,
    int iconCodePoint,
    String iconFontFamily,
    String? iconFontPackage,
    int sortOrder,
  });
}

/// @nodoc
class __$$TagDataImplCopyWithImpl<$Res>
    extends _$TagDataCopyWithImpl<$Res, _$TagDataImpl>
    implements _$$TagDataImplCopyWith<$Res> {
  __$$TagDataImplCopyWithImpl(
    _$TagDataImpl _value,
    $Res Function(_$TagDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TagData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? colorIndex = null,
    Object? iconCodePoint = null,
    Object? iconFontFamily = null,
    Object? iconFontPackage = freezed,
    Object? sortOrder = null,
  }) {
    return _then(
      _$TagDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        colorIndex: null == colorIndex
            ? _value.colorIndex
            : colorIndex // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$TagDataImpl implements _TagData {
  const _$TagDataImpl({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.iconCodePoint,
    required this.iconFontFamily,
    this.iconFontPackage,
    required this.sortOrder,
  });

  factory _$TagDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TagDataImplFromJson(json);

  /// Tag ID - must match row id for integrity check
  @override
  final String id;

  /// Tag name
  @override
  final String name;

  /// Index into color palette
  @override
  final int colorIndex;

  /// Icon code point
  @override
  final int iconCodePoint;

  /// Icon font family
  @override
  final String iconFontFamily;

  /// Icon font package, nullable for MaterialIcons
  @override
  final String? iconFontPackage;

  /// Sort order - duplicated for integrity check
  @override
  final int sortOrder;

  @override
  String toString() {
    return 'TagData(id: $id, name: $name, colorIndex: $colorIndex, iconCodePoint: $iconCodePoint, iconFontFamily: $iconFontFamily, iconFontPackage: $iconFontPackage, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.colorIndex, colorIndex) ||
                other.colorIndex == colorIndex) &&
            (identical(other.iconCodePoint, iconCodePoint) ||
                other.iconCodePoint == iconCodePoint) &&
            (identical(other.iconFontFamily, iconFontFamily) ||
                other.iconFontFamily == iconFontFamily) &&
            (identical(other.iconFontPackage, iconFontPackage) ||
                other.iconFontPackage == iconFontPackage) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    colorIndex,
    iconCodePoint,
    iconFontFamily,
    iconFontPackage,
    sortOrder,
  );

  /// Create a copy of TagData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TagDataImplCopyWith<_$TagDataImpl> get copyWith =>
      __$$TagDataImplCopyWithImpl<_$TagDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TagDataImplToJson(this);
  }
}

abstract class _TagData implements TagData {
  const factory _TagData({
    required final String id,
    required final String name,
    required final int colorIndex,
    required final int iconCodePoint,
    required final String iconFontFamily,
    final String? iconFontPackage,
    required final int sortOrder,
  }) = _$TagDataImpl;

  factory _TagData.fromJson(Map<String, dynamic> json) = _$TagDataImpl.fromJson;

  /// Tag ID - must match row id for integrity check
  @override
  String get id;

  /// Tag name
  @override
  String get name;

  /// Index into color palette
  @override
  int get colorIndex;

  /// Icon code point
  @override
  int get iconCodePoint;

  /// Icon font family
  @override
  String get iconFontFamily;

  /// Icon font package, nullable for MaterialIcons
  @override
  String? get iconFontPackage;

  /// Sort order - duplicated for integrity check
  @override
  int get sortOrder;

  /// Create a copy of TagData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TagDataImplCopyWith<_$TagDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
