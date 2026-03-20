// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BillData _$BillDataFromJson(Map<String, dynamic> json) {
  return _BillData.fromJson(json);
}

/// @nodoc
mixin _$BillData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get currencyCode => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String? get accountId => throw _privateConstructorUsedError;
  int get dueDateMillis => throw _privateConstructorUsedError;
  String get frequency => throw _privateConstructorUsedError;
  bool get isPaid => throw _privateConstructorUsedError;
  int? get paidDateMillis => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  bool get reminderEnabled => throw _privateConstructorUsedError;
  int get reminderDaysBefore => throw _privateConstructorUsedError;
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this BillData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BillData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BillDataCopyWith<BillData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BillDataCopyWith<$Res> {
  factory $BillDataCopyWith(BillData value, $Res Function(BillData) then) =
      _$BillDataCopyWithImpl<$Res, BillData>;
  @useResult
  $Res call({
    String id,
    String name,
    double amount,
    String currencyCode,
    String? categoryId,
    String? accountId,
    int dueDateMillis,
    String frequency,
    bool isPaid,
    int? paidDateMillis,
    String? note,
    bool reminderEnabled,
    int reminderDaysBefore,
    int createdAtMillis,
  });
}

/// @nodoc
class _$BillDataCopyWithImpl<$Res, $Val extends BillData>
    implements $BillDataCopyWith<$Res> {
  _$BillDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BillData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? amount = null,
    Object? currencyCode = null,
    Object? categoryId = freezed,
    Object? accountId = freezed,
    Object? dueDateMillis = null,
    Object? frequency = null,
    Object? isPaid = null,
    Object? paidDateMillis = freezed,
    Object? note = freezed,
    Object? reminderEnabled = null,
    Object? reminderDaysBefore = null,
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
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            currencyCode: null == currencyCode
                ? _value.currencyCode
                : currencyCode // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            accountId: freezed == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            dueDateMillis: null == dueDateMillis
                ? _value.dueDateMillis
                : dueDateMillis // ignore: cast_nullable_to_non_nullable
                      as int,
            frequency: null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as String,
            isPaid: null == isPaid
                ? _value.isPaid
                : isPaid // ignore: cast_nullable_to_non_nullable
                      as bool,
            paidDateMillis: freezed == paidDateMillis
                ? _value.paidDateMillis
                : paidDateMillis // ignore: cast_nullable_to_non_nullable
                      as int?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            reminderEnabled: null == reminderEnabled
                ? _value.reminderEnabled
                : reminderEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            reminderDaysBefore: null == reminderDaysBefore
                ? _value.reminderDaysBefore
                : reminderDaysBefore // ignore: cast_nullable_to_non_nullable
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
abstract class _$$BillDataImplCopyWith<$Res>
    implements $BillDataCopyWith<$Res> {
  factory _$$BillDataImplCopyWith(
    _$BillDataImpl value,
    $Res Function(_$BillDataImpl) then,
  ) = __$$BillDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double amount,
    String currencyCode,
    String? categoryId,
    String? accountId,
    int dueDateMillis,
    String frequency,
    bool isPaid,
    int? paidDateMillis,
    String? note,
    bool reminderEnabled,
    int reminderDaysBefore,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$BillDataImplCopyWithImpl<$Res>
    extends _$BillDataCopyWithImpl<$Res, _$BillDataImpl>
    implements _$$BillDataImplCopyWith<$Res> {
  __$$BillDataImplCopyWithImpl(
    _$BillDataImpl _value,
    $Res Function(_$BillDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BillData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? amount = null,
    Object? currencyCode = null,
    Object? categoryId = freezed,
    Object? accountId = freezed,
    Object? dueDateMillis = null,
    Object? frequency = null,
    Object? isPaid = null,
    Object? paidDateMillis = freezed,
    Object? note = freezed,
    Object? reminderEnabled = null,
    Object? reminderDaysBefore = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$BillDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        currencyCode: null == currencyCode
            ? _value.currencyCode
            : currencyCode // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        accountId: freezed == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        dueDateMillis: null == dueDateMillis
            ? _value.dueDateMillis
            : dueDateMillis // ignore: cast_nullable_to_non_nullable
                  as int,
        frequency: null == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as String,
        isPaid: null == isPaid
            ? _value.isPaid
            : isPaid // ignore: cast_nullable_to_non_nullable
                  as bool,
        paidDateMillis: freezed == paidDateMillis
            ? _value.paidDateMillis
            : paidDateMillis // ignore: cast_nullable_to_non_nullable
                  as int?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        reminderEnabled: null == reminderEnabled
            ? _value.reminderEnabled
            : reminderEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        reminderDaysBefore: null == reminderDaysBefore
            ? _value.reminderDaysBefore
            : reminderDaysBefore // ignore: cast_nullable_to_non_nullable
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
class _$BillDataImpl implements _BillData {
  const _$BillDataImpl({
    required this.id,
    required this.name,
    required this.amount,
    this.currencyCode = 'USD',
    this.categoryId,
    this.accountId,
    required this.dueDateMillis,
    required this.frequency,
    this.isPaid = false,
    this.paidDateMillis,
    this.note,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
    required this.createdAtMillis,
  });

  factory _$BillDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$BillDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double amount;
  @override
  @JsonKey()
  final String currencyCode;
  @override
  final String? categoryId;
  @override
  final String? accountId;
  @override
  final int dueDateMillis;
  @override
  final String frequency;
  @override
  @JsonKey()
  final bool isPaid;
  @override
  final int? paidDateMillis;
  @override
  final String? note;
  @override
  @JsonKey()
  final bool reminderEnabled;
  @override
  @JsonKey()
  final int reminderDaysBefore;
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'BillData(id: $id, name: $name, amount: $amount, currencyCode: $currencyCode, categoryId: $categoryId, accountId: $accountId, dueDateMillis: $dueDateMillis, frequency: $frequency, isPaid: $isPaid, paidDateMillis: $paidDateMillis, note: $note, reminderEnabled: $reminderEnabled, reminderDaysBefore: $reminderDaysBefore, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BillDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.dueDateMillis, dueDateMillis) ||
                other.dueDateMillis == dueDateMillis) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.isPaid, isPaid) || other.isPaid == isPaid) &&
            (identical(other.paidDateMillis, paidDateMillis) ||
                other.paidDateMillis == paidDateMillis) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.reminderEnabled, reminderEnabled) ||
                other.reminderEnabled == reminderEnabled) &&
            (identical(other.reminderDaysBefore, reminderDaysBefore) ||
                other.reminderDaysBefore == reminderDaysBefore) &&
            (identical(other.createdAtMillis, createdAtMillis) ||
                other.createdAtMillis == createdAtMillis));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    amount,
    currencyCode,
    categoryId,
    accountId,
    dueDateMillis,
    frequency,
    isPaid,
    paidDateMillis,
    note,
    reminderEnabled,
    reminderDaysBefore,
    createdAtMillis,
  );

  /// Create a copy of BillData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BillDataImplCopyWith<_$BillDataImpl> get copyWith =>
      __$$BillDataImplCopyWithImpl<_$BillDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BillDataImplToJson(this);
  }
}

abstract class _BillData implements BillData {
  const factory _BillData({
    required final String id,
    required final String name,
    required final double amount,
    final String currencyCode,
    final String? categoryId,
    final String? accountId,
    required final int dueDateMillis,
    required final String frequency,
    final bool isPaid,
    final int? paidDateMillis,
    final String? note,
    final bool reminderEnabled,
    final int reminderDaysBefore,
    required final int createdAtMillis,
  }) = _$BillDataImpl;

  factory _BillData.fromJson(Map<String, dynamic> json) =
      _$BillDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get amount;
  @override
  String get currencyCode;
  @override
  String? get categoryId;
  @override
  String? get accountId;
  @override
  int get dueDateMillis;
  @override
  String get frequency;
  @override
  bool get isPaid;
  @override
  int? get paidDateMillis;
  @override
  String? get note;
  @override
  bool get reminderEnabled;
  @override
  int get reminderDaysBefore;
  @override
  int get createdAtMillis;

  /// Create a copy of BillData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BillDataImplCopyWith<_$BillDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
