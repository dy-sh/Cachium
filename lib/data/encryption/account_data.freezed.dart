// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AccountData _$AccountDataFromJson(Map<String, dynamic> json) {
  return _AccountData.fromJson(json);
}

/// @nodoc
mixin _$AccountData {
  /// Duplicated for integrity check - must match row id
  String get id => throw _privateConstructorUsedError;

  /// Account name
  String get name => throw _privateConstructorUsedError;

  /// Account type: 'bank', 'creditCard', 'cash', 'savings', 'investment', 'wallet'
  String get type => throw _privateConstructorUsedError;

  /// Current balance
  double get balance => throw _privateConstructorUsedError;

  /// Initial balance when account was created (for recalculation)
  double get initialBalance => throw _privateConstructorUsedError;

  /// Custom color value (optional) - stored as int for serialization
  int? get customColorValue => throw _privateConstructorUsedError;

  /// Custom icon code point (optional)
  int? get customIconCodePoint => throw _privateConstructorUsedError;

  /// Duplicated for integrity check - must match row createdAt
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this AccountData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountDataCopyWith<AccountData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountDataCopyWith<$Res> {
  factory $AccountDataCopyWith(
    AccountData value,
    $Res Function(AccountData) then,
  ) = _$AccountDataCopyWithImpl<$Res, AccountData>;
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    double balance,
    double initialBalance,
    int? customColorValue,
    int? customIconCodePoint,
    int createdAtMillis,
  });
}

/// @nodoc
class _$AccountDataCopyWithImpl<$Res, $Val extends AccountData>
    implements $AccountDataCopyWith<$Res> {
  _$AccountDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? balance = null,
    Object? initialBalance = null,
    Object? customColorValue = freezed,
    Object? customIconCodePoint = freezed,
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
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            balance: null == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double,
            initialBalance: null == initialBalance
                ? _value.initialBalance
                : initialBalance // ignore: cast_nullable_to_non_nullable
                      as double,
            customColorValue: freezed == customColorValue
                ? _value.customColorValue
                : customColorValue // ignore: cast_nullable_to_non_nullable
                      as int?,
            customIconCodePoint: freezed == customIconCodePoint
                ? _value.customIconCodePoint
                : customIconCodePoint // ignore: cast_nullable_to_non_nullable
                      as int?,
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
abstract class _$$AccountDataImplCopyWith<$Res>
    implements $AccountDataCopyWith<$Res> {
  factory _$$AccountDataImplCopyWith(
    _$AccountDataImpl value,
    $Res Function(_$AccountDataImpl) then,
  ) = __$$AccountDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    double balance,
    double initialBalance,
    int? customColorValue,
    int? customIconCodePoint,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$AccountDataImplCopyWithImpl<$Res>
    extends _$AccountDataCopyWithImpl<$Res, _$AccountDataImpl>
    implements _$$AccountDataImplCopyWith<$Res> {
  __$$AccountDataImplCopyWithImpl(
    _$AccountDataImpl _value,
    $Res Function(_$AccountDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? balance = null,
    Object? initialBalance = null,
    Object? customColorValue = freezed,
    Object? customIconCodePoint = freezed,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$AccountDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double,
        initialBalance: null == initialBalance
            ? _value.initialBalance
            : initialBalance // ignore: cast_nullable_to_non_nullable
                  as double,
        customColorValue: freezed == customColorValue
            ? _value.customColorValue
            : customColorValue // ignore: cast_nullable_to_non_nullable
                  as int?,
        customIconCodePoint: freezed == customIconCodePoint
            ? _value.customIconCodePoint
            : customIconCodePoint // ignore: cast_nullable_to_non_nullable
                  as int?,
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
class _$AccountDataImpl implements _AccountData {
  const _$AccountDataImpl({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.initialBalance = 0.0,
    this.customColorValue,
    this.customIconCodePoint,
    required this.createdAtMillis,
  });

  factory _$AccountDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountDataImplFromJson(json);

  /// Duplicated for integrity check - must match row id
  @override
  final String id;

  /// Account name
  @override
  final String name;

  /// Account type: 'bank', 'creditCard', 'cash', 'savings', 'investment', 'wallet'
  @override
  final String type;

  /// Current balance
  @override
  final double balance;

  /// Initial balance when account was created (for recalculation)
  @override
  @JsonKey()
  final double initialBalance;

  /// Custom color value (optional) - stored as int for serialization
  @override
  final int? customColorValue;

  /// Custom icon code point (optional)
  @override
  final int? customIconCodePoint;

  /// Duplicated for integrity check - must match row createdAt
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'AccountData(id: $id, name: $name, type: $type, balance: $balance, initialBalance: $initialBalance, customColorValue: $customColorValue, customIconCodePoint: $customIconCodePoint, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.initialBalance, initialBalance) ||
                other.initialBalance == initialBalance) &&
            (identical(other.customColorValue, customColorValue) ||
                other.customColorValue == customColorValue) &&
            (identical(other.customIconCodePoint, customIconCodePoint) ||
                other.customIconCodePoint == customIconCodePoint) &&
            (identical(other.createdAtMillis, createdAtMillis) ||
                other.createdAtMillis == createdAtMillis));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    type,
    balance,
    initialBalance,
    customColorValue,
    customIconCodePoint,
    createdAtMillis,
  );

  /// Create a copy of AccountData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountDataImplCopyWith<_$AccountDataImpl> get copyWith =>
      __$$AccountDataImplCopyWithImpl<_$AccountDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountDataImplToJson(this);
  }
}

abstract class _AccountData implements AccountData {
  const factory _AccountData({
    required final String id,
    required final String name,
    required final String type,
    required final double balance,
    final double initialBalance,
    final int? customColorValue,
    final int? customIconCodePoint,
    required final int createdAtMillis,
  }) = _$AccountDataImpl;

  factory _AccountData.fromJson(Map<String, dynamic> json) =
      _$AccountDataImpl.fromJson;

  /// Duplicated for integrity check - must match row id
  @override
  String get id;

  /// Account name
  @override
  String get name;

  /// Account type: 'bank', 'creditCard', 'cash', 'savings', 'investment', 'wallet'
  @override
  String get type;

  /// Current balance
  @override
  double get balance;

  /// Initial balance when account was created (for recalculation)
  @override
  double get initialBalance;

  /// Custom color value (optional) - stored as int for serialization
  @override
  int? get customColorValue;

  /// Custom icon code point (optional)
  @override
  int? get customIconCodePoint;

  /// Duplicated for integrity check - must match row createdAt
  @override
  int get createdAtMillis;

  /// Create a copy of AccountData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountDataImplCopyWith<_$AccountDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
