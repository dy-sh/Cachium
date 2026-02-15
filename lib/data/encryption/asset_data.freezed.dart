// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AssetData _$AssetDataFromJson(Map<String, dynamic> json) {
  return _AssetData.fromJson(json);
}

/// @nodoc
mixin _$AssetData {
  /// Duplicated for integrity check - must match row id
  String get id => throw _privateConstructorUsedError;

  /// Asset name
  String get name => throw _privateConstructorUsedError;

  /// Icon code point (from IconData)
  int get iconCodePoint => throw _privateConstructorUsedError;

  /// Icon font family
  String? get iconFontFamily => throw _privateConstructorUsedError;

  /// Icon font package
  String? get iconFontPackage => throw _privateConstructorUsedError;

  /// Color index in accent palette (0-23)
  int get colorIndex => throw _privateConstructorUsedError;

  /// Asset status: 'active' or 'sold'
  String get status => throw _privateConstructorUsedError;

  /// Optional description/note
  String? get note => throw _privateConstructorUsedError;

  /// Matches the database createdAt field for integrity verification during import.
  /// Not exported as a separate CSV column to avoid duplication.
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this AssetData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssetData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetDataCopyWith<AssetData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetDataCopyWith<$Res> {
  factory $AssetDataCopyWith(AssetData value, $Res Function(AssetData) then) =
      _$AssetDataCopyWithImpl<$Res, AssetData>;
  @useResult
  $Res call({
    String id,
    String name,
    int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    int colorIndex,
    String status,
    String? note,
    int createdAtMillis,
  });
}

/// @nodoc
class _$AssetDataCopyWithImpl<$Res, $Val extends AssetData>
    implements $AssetDataCopyWith<$Res> {
  _$AssetDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssetData
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
    Object? status = null,
    Object? note = freezed,
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
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$AssetDataImplCopyWith<$Res>
    implements $AssetDataCopyWith<$Res> {
  factory _$$AssetDataImplCopyWith(
    _$AssetDataImpl value,
    $Res Function(_$AssetDataImpl) then,
  ) = __$$AssetDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    int colorIndex,
    String status,
    String? note,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$AssetDataImplCopyWithImpl<$Res>
    extends _$AssetDataCopyWithImpl<$Res, _$AssetDataImpl>
    implements _$$AssetDataImplCopyWith<$Res> {
  __$$AssetDataImplCopyWithImpl(
    _$AssetDataImpl _value,
    $Res Function(_$AssetDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssetData
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
    Object? status = null,
    Object? note = freezed,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$AssetDataImpl(
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
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$AssetDataImpl implements _AssetData {
  const _$AssetDataImpl({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.colorIndex,
    required this.status,
    this.note,
    required this.createdAtMillis,
  });

  factory _$AssetDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetDataImplFromJson(json);

  /// Duplicated for integrity check - must match row id
  @override
  final String id;

  /// Asset name
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

  /// Asset status: 'active' or 'sold'
  @override
  final String status;

  /// Optional description/note
  @override
  final String? note;

  /// Matches the database createdAt field for integrity verification during import.
  /// Not exported as a separate CSV column to avoid duplication.
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'AssetData(id: $id, name: $name, iconCodePoint: $iconCodePoint, iconFontFamily: $iconFontFamily, iconFontPackage: $iconFontPackage, colorIndex: $colorIndex, status: $status, note: $note, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetDataImpl &&
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
            (identical(other.status, status) || other.status == status) &&
            (identical(other.note, note) || other.note == note) &&
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
    status,
    note,
    createdAtMillis,
  );

  /// Create a copy of AssetData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetDataImplCopyWith<_$AssetDataImpl> get copyWith =>
      __$$AssetDataImplCopyWithImpl<_$AssetDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetDataImplToJson(this);
  }
}

abstract class _AssetData implements AssetData {
  const factory _AssetData({
    required final String id,
    required final String name,
    required final int iconCodePoint,
    final String? iconFontFamily,
    final String? iconFontPackage,
    required final int colorIndex,
    required final String status,
    final String? note,
    required final int createdAtMillis,
  }) = _$AssetDataImpl;

  factory _AssetData.fromJson(Map<String, dynamic> json) =
      _$AssetDataImpl.fromJson;

  /// Duplicated for integrity check - must match row id
  @override
  String get id;

  /// Asset name
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

  /// Asset status: 'active' or 'sold'
  @override
  String get status;

  /// Optional description/note
  @override
  String? get note;

  /// Matches the database createdAt field for integrity verification during import.
  /// Not exported as a separate CSV column to avoid duplication.
  @override
  int get createdAtMillis;

  /// Create a copy of AssetData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetDataImplCopyWith<_$AssetDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
