// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_rule_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RecurringRuleData _$RecurringRuleDataFromJson(Map<String, dynamic> json) {
  return _RecurringRuleData.fromJson(json);
}

/// @nodoc
mixin _$RecurringRuleData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  String get accountId => throw _privateConstructorUsedError;
  String? get destinationAccountId => throw _privateConstructorUsedError;
  String? get merchant => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String get frequency => throw _privateConstructorUsedError;
  int get startDateMillis => throw _privateConstructorUsedError;
  int? get endDateMillis => throw _privateConstructorUsedError;
  int get lastGeneratedDateMillis => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this RecurringRuleData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecurringRuleData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecurringRuleDataCopyWith<RecurringRuleData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecurringRuleDataCopyWith<$Res> {
  factory $RecurringRuleDataCopyWith(
    RecurringRuleData value,
    $Res Function(RecurringRuleData) then,
  ) = _$RecurringRuleDataCopyWithImpl<$Res, RecurringRuleData>;
  @useResult
  $Res call({
    String id,
    String name,
    double amount,
    String type,
    String categoryId,
    String accountId,
    String? destinationAccountId,
    String? merchant,
    String? note,
    String frequency,
    int startDateMillis,
    int? endDateMillis,
    int lastGeneratedDateMillis,
    bool isActive,
    int createdAtMillis,
  });
}

/// @nodoc
class _$RecurringRuleDataCopyWithImpl<$Res, $Val extends RecurringRuleData>
    implements $RecurringRuleDataCopyWith<$Res> {
  _$RecurringRuleDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecurringRuleData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? amount = null,
    Object? type = null,
    Object? categoryId = null,
    Object? accountId = null,
    Object? destinationAccountId = freezed,
    Object? merchant = freezed,
    Object? note = freezed,
    Object? frequency = null,
    Object? startDateMillis = null,
    Object? endDateMillis = freezed,
    Object? lastGeneratedDateMillis = null,
    Object? isActive = null,
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
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            destinationAccountId: freezed == destinationAccountId
                ? _value.destinationAccountId
                : destinationAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            merchant: freezed == merchant
                ? _value.merchant
                : merchant // ignore: cast_nullable_to_non_nullable
                      as String?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            frequency: null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as String,
            startDateMillis: null == startDateMillis
                ? _value.startDateMillis
                : startDateMillis // ignore: cast_nullable_to_non_nullable
                      as int,
            endDateMillis: freezed == endDateMillis
                ? _value.endDateMillis
                : endDateMillis // ignore: cast_nullable_to_non_nullable
                      as int?,
            lastGeneratedDateMillis: null == lastGeneratedDateMillis
                ? _value.lastGeneratedDateMillis
                : lastGeneratedDateMillis // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$RecurringRuleDataImplCopyWith<$Res>
    implements $RecurringRuleDataCopyWith<$Res> {
  factory _$$RecurringRuleDataImplCopyWith(
    _$RecurringRuleDataImpl value,
    $Res Function(_$RecurringRuleDataImpl) then,
  ) = __$$RecurringRuleDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double amount,
    String type,
    String categoryId,
    String accountId,
    String? destinationAccountId,
    String? merchant,
    String? note,
    String frequency,
    int startDateMillis,
    int? endDateMillis,
    int lastGeneratedDateMillis,
    bool isActive,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$RecurringRuleDataImplCopyWithImpl<$Res>
    extends _$RecurringRuleDataCopyWithImpl<$Res, _$RecurringRuleDataImpl>
    implements _$$RecurringRuleDataImplCopyWith<$Res> {
  __$$RecurringRuleDataImplCopyWithImpl(
    _$RecurringRuleDataImpl _value,
    $Res Function(_$RecurringRuleDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecurringRuleData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? amount = null,
    Object? type = null,
    Object? categoryId = null,
    Object? accountId = null,
    Object? destinationAccountId = freezed,
    Object? merchant = freezed,
    Object? note = freezed,
    Object? frequency = null,
    Object? startDateMillis = null,
    Object? endDateMillis = freezed,
    Object? lastGeneratedDateMillis = null,
    Object? isActive = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$RecurringRuleDataImpl(
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
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        destinationAccountId: freezed == destinationAccountId
            ? _value.destinationAccountId
            : destinationAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchant: freezed == merchant
            ? _value.merchant
            : merchant // ignore: cast_nullable_to_non_nullable
                  as String?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        frequency: null == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as String,
        startDateMillis: null == startDateMillis
            ? _value.startDateMillis
            : startDateMillis // ignore: cast_nullable_to_non_nullable
                  as int,
        endDateMillis: freezed == endDateMillis
            ? _value.endDateMillis
            : endDateMillis // ignore: cast_nullable_to_non_nullable
                  as int?,
        lastGeneratedDateMillis: null == lastGeneratedDateMillis
            ? _value.lastGeneratedDateMillis
            : lastGeneratedDateMillis // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$RecurringRuleDataImpl implements _RecurringRuleData {
  const _$RecurringRuleDataImpl({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.destinationAccountId,
    this.merchant,
    this.note,
    required this.frequency,
    required this.startDateMillis,
    this.endDateMillis,
    required this.lastGeneratedDateMillis,
    this.isActive = true,
    required this.createdAtMillis,
  });

  factory _$RecurringRuleDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecurringRuleDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double amount;
  @override
  final String type;
  @override
  final String categoryId;
  @override
  final String accountId;
  @override
  final String? destinationAccountId;
  @override
  final String? merchant;
  @override
  final String? note;
  @override
  final String frequency;
  @override
  final int startDateMillis;
  @override
  final int? endDateMillis;
  @override
  final int lastGeneratedDateMillis;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'RecurringRuleData(id: $id, name: $name, amount: $amount, type: $type, categoryId: $categoryId, accountId: $accountId, destinationAccountId: $destinationAccountId, merchant: $merchant, note: $note, frequency: $frequency, startDateMillis: $startDateMillis, endDateMillis: $endDateMillis, lastGeneratedDateMillis: $lastGeneratedDateMillis, isActive: $isActive, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecurringRuleDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.destinationAccountId, destinationAccountId) ||
                other.destinationAccountId == destinationAccountId) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.startDateMillis, startDateMillis) ||
                other.startDateMillis == startDateMillis) &&
            (identical(other.endDateMillis, endDateMillis) ||
                other.endDateMillis == endDateMillis) &&
            (identical(
                  other.lastGeneratedDateMillis,
                  lastGeneratedDateMillis,
                ) ||
                other.lastGeneratedDateMillis == lastGeneratedDateMillis) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
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
    type,
    categoryId,
    accountId,
    destinationAccountId,
    merchant,
    note,
    frequency,
    startDateMillis,
    endDateMillis,
    lastGeneratedDateMillis,
    isActive,
    createdAtMillis,
  );

  /// Create a copy of RecurringRuleData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecurringRuleDataImplCopyWith<_$RecurringRuleDataImpl> get copyWith =>
      __$$RecurringRuleDataImplCopyWithImpl<_$RecurringRuleDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecurringRuleDataImplToJson(this);
  }
}

abstract class _RecurringRuleData implements RecurringRuleData {
  const factory _RecurringRuleData({
    required final String id,
    required final String name,
    required final double amount,
    required final String type,
    required final String categoryId,
    required final String accountId,
    final String? destinationAccountId,
    final String? merchant,
    final String? note,
    required final String frequency,
    required final int startDateMillis,
    final int? endDateMillis,
    required final int lastGeneratedDateMillis,
    final bool isActive,
    required final int createdAtMillis,
  }) = _$RecurringRuleDataImpl;

  factory _RecurringRuleData.fromJson(Map<String, dynamic> json) =
      _$RecurringRuleDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get amount;
  @override
  String get type;
  @override
  String get categoryId;
  @override
  String get accountId;
  @override
  String? get destinationAccountId;
  @override
  String? get merchant;
  @override
  String? get note;
  @override
  String get frequency;
  @override
  int get startDateMillis;
  @override
  int? get endDateMillis;
  @override
  int get lastGeneratedDateMillis;
  @override
  bool get isActive;
  @override
  int get createdAtMillis;

  /// Create a copy of RecurringRuleData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecurringRuleDataImplCopyWith<_$RecurringRuleDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
