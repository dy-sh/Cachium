// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'savings_goal_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SavingsGoalData _$SavingsGoalDataFromJson(Map<String, dynamic> json) {
  return _SavingsGoalData.fromJson(json);
}

/// @nodoc
mixin _$SavingsGoalData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get targetAmount => throw _privateConstructorUsedError;
  double get currentAmount => throw _privateConstructorUsedError;
  int get colorIndex => throw _privateConstructorUsedError;
  int get iconCodePoint => throw _privateConstructorUsedError;
  String? get iconFontFamily => throw _privateConstructorUsedError;
  String? get iconFontPackage => throw _privateConstructorUsedError;
  String? get linkedAccountId => throw _privateConstructorUsedError;
  int? get targetDateMillis => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this SavingsGoalData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SavingsGoalData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SavingsGoalDataCopyWith<SavingsGoalData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavingsGoalDataCopyWith<$Res> {
  factory $SavingsGoalDataCopyWith(
    SavingsGoalData value,
    $Res Function(SavingsGoalData) then,
  ) = _$SavingsGoalDataCopyWithImpl<$Res, SavingsGoalData>;
  @useResult
  $Res call({
    String id,
    String name,
    double targetAmount,
    double currentAmount,
    int colorIndex,
    int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    String? linkedAccountId,
    int? targetDateMillis,
    String? note,
    int createdAtMillis,
  });
}

/// @nodoc
class _$SavingsGoalDataCopyWithImpl<$Res, $Val extends SavingsGoalData>
    implements $SavingsGoalDataCopyWith<$Res> {
  _$SavingsGoalDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SavingsGoalData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetAmount = null,
    Object? currentAmount = null,
    Object? colorIndex = null,
    Object? iconCodePoint = null,
    Object? iconFontFamily = freezed,
    Object? iconFontPackage = freezed,
    Object? linkedAccountId = freezed,
    Object? targetDateMillis = freezed,
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
            targetAmount: null == targetAmount
                ? _value.targetAmount
                : targetAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            currentAmount: null == currentAmount
                ? _value.currentAmount
                : currentAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            colorIndex: null == colorIndex
                ? _value.colorIndex
                : colorIndex // ignore: cast_nullable_to_non_nullable
                      as int,
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
            linkedAccountId: freezed == linkedAccountId
                ? _value.linkedAccountId
                : linkedAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetDateMillis: freezed == targetDateMillis
                ? _value.targetDateMillis
                : targetDateMillis // ignore: cast_nullable_to_non_nullable
                      as int?,
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
abstract class _$$SavingsGoalDataImplCopyWith<$Res>
    implements $SavingsGoalDataCopyWith<$Res> {
  factory _$$SavingsGoalDataImplCopyWith(
    _$SavingsGoalDataImpl value,
    $Res Function(_$SavingsGoalDataImpl) then,
  ) = __$$SavingsGoalDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double targetAmount,
    double currentAmount,
    int colorIndex,
    int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    String? linkedAccountId,
    int? targetDateMillis,
    String? note,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$SavingsGoalDataImplCopyWithImpl<$Res>
    extends _$SavingsGoalDataCopyWithImpl<$Res, _$SavingsGoalDataImpl>
    implements _$$SavingsGoalDataImplCopyWith<$Res> {
  __$$SavingsGoalDataImplCopyWithImpl(
    _$SavingsGoalDataImpl _value,
    $Res Function(_$SavingsGoalDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SavingsGoalData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetAmount = null,
    Object? currentAmount = null,
    Object? colorIndex = null,
    Object? iconCodePoint = null,
    Object? iconFontFamily = freezed,
    Object? iconFontPackage = freezed,
    Object? linkedAccountId = freezed,
    Object? targetDateMillis = freezed,
    Object? note = freezed,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$SavingsGoalDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        targetAmount: null == targetAmount
            ? _value.targetAmount
            : targetAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        currentAmount: null == currentAmount
            ? _value.currentAmount
            : currentAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        colorIndex: null == colorIndex
            ? _value.colorIndex
            : colorIndex // ignore: cast_nullable_to_non_nullable
                  as int,
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
        linkedAccountId: freezed == linkedAccountId
            ? _value.linkedAccountId
            : linkedAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetDateMillis: freezed == targetDateMillis
            ? _value.targetDateMillis
            : targetDateMillis // ignore: cast_nullable_to_non_nullable
                  as int?,
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
class _$SavingsGoalDataImpl implements _SavingsGoalData {
  const _$SavingsGoalDataImpl({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.colorIndex,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    this.linkedAccountId,
    this.targetDateMillis,
    this.note,
    required this.createdAtMillis,
  });

  factory _$SavingsGoalDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SavingsGoalDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double targetAmount;
  @override
  @JsonKey()
  final double currentAmount;
  @override
  final int colorIndex;
  @override
  final int iconCodePoint;
  @override
  final String? iconFontFamily;
  @override
  final String? iconFontPackage;
  @override
  final String? linkedAccountId;
  @override
  final int? targetDateMillis;
  @override
  final String? note;
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'SavingsGoalData(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, colorIndex: $colorIndex, iconCodePoint: $iconCodePoint, iconFontFamily: $iconFontFamily, iconFontPackage: $iconFontPackage, linkedAccountId: $linkedAccountId, targetDateMillis: $targetDateMillis, note: $note, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavingsGoalDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetAmount, targetAmount) ||
                other.targetAmount == targetAmount) &&
            (identical(other.currentAmount, currentAmount) ||
                other.currentAmount == currentAmount) &&
            (identical(other.colorIndex, colorIndex) ||
                other.colorIndex == colorIndex) &&
            (identical(other.iconCodePoint, iconCodePoint) ||
                other.iconCodePoint == iconCodePoint) &&
            (identical(other.iconFontFamily, iconFontFamily) ||
                other.iconFontFamily == iconFontFamily) &&
            (identical(other.iconFontPackage, iconFontPackage) ||
                other.iconFontPackage == iconFontPackage) &&
            (identical(other.linkedAccountId, linkedAccountId) ||
                other.linkedAccountId == linkedAccountId) &&
            (identical(other.targetDateMillis, targetDateMillis) ||
                other.targetDateMillis == targetDateMillis) &&
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
    targetAmount,
    currentAmount,
    colorIndex,
    iconCodePoint,
    iconFontFamily,
    iconFontPackage,
    linkedAccountId,
    targetDateMillis,
    note,
    createdAtMillis,
  );

  /// Create a copy of SavingsGoalData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SavingsGoalDataImplCopyWith<_$SavingsGoalDataImpl> get copyWith =>
      __$$SavingsGoalDataImplCopyWithImpl<_$SavingsGoalDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SavingsGoalDataImplToJson(this);
  }
}

abstract class _SavingsGoalData implements SavingsGoalData {
  const factory _SavingsGoalData({
    required final String id,
    required final String name,
    required final double targetAmount,
    final double currentAmount,
    required final int colorIndex,
    required final int iconCodePoint,
    final String? iconFontFamily,
    final String? iconFontPackage,
    final String? linkedAccountId,
    final int? targetDateMillis,
    final String? note,
    required final int createdAtMillis,
  }) = _$SavingsGoalDataImpl;

  factory _SavingsGoalData.fromJson(Map<String, dynamic> json) =
      _$SavingsGoalDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get targetAmount;
  @override
  double get currentAmount;
  @override
  int get colorIndex;
  @override
  int get iconCodePoint;
  @override
  String? get iconFontFamily;
  @override
  String? get iconFontPackage;
  @override
  String? get linkedAccountId;
  @override
  int? get targetDateMillis;
  @override
  String? get note;
  @override
  int get createdAtMillis;

  /// Create a copy of SavingsGoalData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SavingsGoalDataImplCopyWith<_$SavingsGoalDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
