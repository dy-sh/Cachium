// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BudgetData _$BudgetDataFromJson(Map<String, dynamic> json) {
  return _BudgetData.fromJson(json);
}

/// @nodoc
mixin _$BudgetData {
  String get id => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  int get month => throw _privateConstructorUsedError;
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this BudgetData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BudgetData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetDataCopyWith<BudgetData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetDataCopyWith<$Res> {
  factory $BudgetDataCopyWith(
    BudgetData value,
    $Res Function(BudgetData) then,
  ) = _$BudgetDataCopyWithImpl<$Res, BudgetData>;
  @useResult
  $Res call({
    String id,
    String categoryId,
    double amount,
    int year,
    int month,
    int createdAtMillis,
  });
}

/// @nodoc
class _$BudgetDataCopyWithImpl<$Res, $Val extends BudgetData>
    implements $BudgetDataCopyWith<$Res> {
  _$BudgetDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? amount = null,
    Object? year = null,
    Object? month = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            year: null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int,
            month: null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
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
abstract class _$$BudgetDataImplCopyWith<$Res>
    implements $BudgetDataCopyWith<$Res> {
  factory _$$BudgetDataImplCopyWith(
    _$BudgetDataImpl value,
    $Res Function(_$BudgetDataImpl) then,
  ) = __$$BudgetDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String categoryId,
    double amount,
    int year,
    int month,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$BudgetDataImplCopyWithImpl<$Res>
    extends _$BudgetDataCopyWithImpl<$Res, _$BudgetDataImpl>
    implements _$$BudgetDataImplCopyWith<$Res> {
  __$$BudgetDataImplCopyWithImpl(
    _$BudgetDataImpl _value,
    $Res Function(_$BudgetDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BudgetData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? amount = null,
    Object? year = null,
    Object? month = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$BudgetDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        year: null == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _value.month
            : month // ignore: cast_nullable_to_non_nullable
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
class _$BudgetDataImpl implements _BudgetData {
  const _$BudgetDataImpl({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.year,
    required this.month,
    required this.createdAtMillis,
  });

  factory _$BudgetDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$BudgetDataImplFromJson(json);

  @override
  final String id;
  @override
  final String categoryId;
  @override
  final double amount;
  @override
  final int year;
  @override
  final int month;
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'BudgetData(id: $id, categoryId: $categoryId, amount: $amount, year: $year, month: $month, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.createdAtMillis, createdAtMillis) ||
                other.createdAtMillis == createdAtMillis));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    categoryId,
    amount,
    year,
    month,
    createdAtMillis,
  );

  /// Create a copy of BudgetData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetDataImplCopyWith<_$BudgetDataImpl> get copyWith =>
      __$$BudgetDataImplCopyWithImpl<_$BudgetDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BudgetDataImplToJson(this);
  }
}

abstract class _BudgetData implements BudgetData {
  const factory _BudgetData({
    required final String id,
    required final String categoryId,
    required final double amount,
    required final int year,
    required final int month,
    required final int createdAtMillis,
  }) = _$BudgetDataImpl;

  factory _BudgetData.fromJson(Map<String, dynamic> json) =
      _$BudgetDataImpl.fromJson;

  @override
  String get id;
  @override
  String get categoryId;
  @override
  double get amount;
  @override
  int get year;
  @override
  int get month;
  @override
  int get createdAtMillis;

  /// Create a copy of BudgetData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetDataImplCopyWith<_$BudgetDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
