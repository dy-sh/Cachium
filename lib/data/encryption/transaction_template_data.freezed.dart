// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_template_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TransactionTemplateData _$TransactionTemplateDataFromJson(
  Map<String, dynamic> json,
) {
  return _TransactionTemplateData.fromJson(json);
}

/// @nodoc
mixin _$TransactionTemplateData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double? get amount => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String? get accountId => throw _privateConstructorUsedError;
  String? get destinationAccountId => throw _privateConstructorUsedError;
  String? get assetId => throw _privateConstructorUsedError;
  String? get merchant => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this TransactionTemplateData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionTemplateData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionTemplateDataCopyWith<TransactionTemplateData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionTemplateDataCopyWith<$Res> {
  factory $TransactionTemplateDataCopyWith(
    TransactionTemplateData value,
    $Res Function(TransactionTemplateData) then,
  ) = _$TransactionTemplateDataCopyWithImpl<$Res, TransactionTemplateData>;
  @useResult
  $Res call({
    String id,
    String name,
    double? amount,
    String type,
    String? categoryId,
    String? accountId,
    String? destinationAccountId,
    String? assetId,
    String? merchant,
    String? note,
    int createdAtMillis,
  });
}

/// @nodoc
class _$TransactionTemplateDataCopyWithImpl<
  $Res,
  $Val extends TransactionTemplateData
>
    implements $TransactionTemplateDataCopyWith<$Res> {
  _$TransactionTemplateDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionTemplateData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? amount = freezed,
    Object? type = null,
    Object? categoryId = freezed,
    Object? accountId = freezed,
    Object? destinationAccountId = freezed,
    Object? assetId = freezed,
    Object? merchant = freezed,
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
            amount: freezed == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            accountId: freezed == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            destinationAccountId: freezed == destinationAccountId
                ? _value.destinationAccountId
                : destinationAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            assetId: freezed == assetId
                ? _value.assetId
                : assetId // ignore: cast_nullable_to_non_nullable
                      as String?,
            merchant: freezed == merchant
                ? _value.merchant
                : merchant // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$TransactionTemplateDataImplCopyWith<$Res>
    implements $TransactionTemplateDataCopyWith<$Res> {
  factory _$$TransactionTemplateDataImplCopyWith(
    _$TransactionTemplateDataImpl value,
    $Res Function(_$TransactionTemplateDataImpl) then,
  ) = __$$TransactionTemplateDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double? amount,
    String type,
    String? categoryId,
    String? accountId,
    String? destinationAccountId,
    String? assetId,
    String? merchant,
    String? note,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$TransactionTemplateDataImplCopyWithImpl<$Res>
    extends
        _$TransactionTemplateDataCopyWithImpl<
          $Res,
          _$TransactionTemplateDataImpl
        >
    implements _$$TransactionTemplateDataImplCopyWith<$Res> {
  __$$TransactionTemplateDataImplCopyWithImpl(
    _$TransactionTemplateDataImpl _value,
    $Res Function(_$TransactionTemplateDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransactionTemplateData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? amount = freezed,
    Object? type = null,
    Object? categoryId = freezed,
    Object? accountId = freezed,
    Object? destinationAccountId = freezed,
    Object? assetId = freezed,
    Object? merchant = freezed,
    Object? note = freezed,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$TransactionTemplateDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: freezed == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        accountId: freezed == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        destinationAccountId: freezed == destinationAccountId
            ? _value.destinationAccountId
            : destinationAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        assetId: freezed == assetId
            ? _value.assetId
            : assetId // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchant: freezed == merchant
            ? _value.merchant
            : merchant // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$TransactionTemplateDataImpl implements _TransactionTemplateData {
  const _$TransactionTemplateDataImpl({
    required this.id,
    required this.name,
    this.amount,
    required this.type,
    this.categoryId,
    this.accountId,
    this.destinationAccountId,
    this.assetId,
    this.merchant,
    this.note,
    required this.createdAtMillis,
  });

  factory _$TransactionTemplateDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionTemplateDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double? amount;
  @override
  final String type;
  @override
  final String? categoryId;
  @override
  final String? accountId;
  @override
  final String? destinationAccountId;
  @override
  final String? assetId;
  @override
  final String? merchant;
  @override
  final String? note;
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'TransactionTemplateData(id: $id, name: $name, amount: $amount, type: $type, categoryId: $categoryId, accountId: $accountId, destinationAccountId: $destinationAccountId, assetId: $assetId, merchant: $merchant, note: $note, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionTemplateDataImpl &&
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
            (identical(other.assetId, assetId) || other.assetId == assetId) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
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
    amount,
    type,
    categoryId,
    accountId,
    destinationAccountId,
    assetId,
    merchant,
    note,
    createdAtMillis,
  );

  /// Create a copy of TransactionTemplateData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionTemplateDataImplCopyWith<_$TransactionTemplateDataImpl>
  get copyWith =>
      __$$TransactionTemplateDataImplCopyWithImpl<
        _$TransactionTemplateDataImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionTemplateDataImplToJson(this);
  }
}

abstract class _TransactionTemplateData implements TransactionTemplateData {
  const factory _TransactionTemplateData({
    required final String id,
    required final String name,
    final double? amount,
    required final String type,
    final String? categoryId,
    final String? accountId,
    final String? destinationAccountId,
    final String? assetId,
    final String? merchant,
    final String? note,
    required final int createdAtMillis,
  }) = _$TransactionTemplateDataImpl;

  factory _TransactionTemplateData.fromJson(Map<String, dynamic> json) =
      _$TransactionTemplateDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double? get amount;
  @override
  String get type;
  @override
  String? get categoryId;
  @override
  String? get accountId;
  @override
  String? get destinationAccountId;
  @override
  String? get assetId;
  @override
  String? get merchant;
  @override
  String? get note;
  @override
  int get createdAtMillis;

  /// Create a copy of TransactionTemplateData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionTemplateDataImplCopyWith<_$TransactionTemplateDataImpl>
  get copyWith => throw _privateConstructorUsedError;
}
