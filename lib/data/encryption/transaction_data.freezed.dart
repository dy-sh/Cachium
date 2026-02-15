// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TransactionData _$TransactionDataFromJson(Map<String, dynamic> json) {
  return _TransactionData.fromJson(json);
}

/// @nodoc
mixin _$TransactionData {
  /// Duplicated for integrity check - must match row id
  String get id => throw _privateConstructorUsedError;

  /// Transaction amount (positive value)
  double get amount => throw _privateConstructorUsedError;

  /// Reference to the category
  String get categoryId => throw _privateConstructorUsedError;

  /// Reference to the account
  String get accountId => throw _privateConstructorUsedError;

  /// Transaction type: 'income' or 'expense'
  String get type => throw _privateConstructorUsedError;

  /// Optional note/memo for the transaction
  String? get note => throw _privateConstructorUsedError;

  /// Optional merchant/payee name
  String? get merchant => throw _privateConstructorUsedError;

  /// For transfers: the destination account ID
  String? get destinationAccountId => throw _privateConstructorUsedError;

  /// Currency code (default: USD)
  String get currency => throw _privateConstructorUsedError;

  /// Matches the database date field for integrity verification during import.
  /// Not exported as a separate CSV column to avoid duplication.
  int get dateMillis => throw _privateConstructorUsedError;

  /// When the transaction was created (internal metadata only).
  /// Not exported as a separate CSV column to avoid duplication.
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this TransactionData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionDataCopyWith<TransactionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionDataCopyWith<$Res> {
  factory $TransactionDataCopyWith(
    TransactionData value,
    $Res Function(TransactionData) then,
  ) = _$TransactionDataCopyWithImpl<$Res, TransactionData>;
  @useResult
  $Res call({
    String id,
    double amount,
    String categoryId,
    String accountId,
    String type,
    String? note,
    String? merchant,
    String? destinationAccountId,
    String currency,
    int dateMillis,
    int createdAtMillis,
  });
}

/// @nodoc
class _$TransactionDataCopyWithImpl<$Res, $Val extends TransactionData>
    implements $TransactionDataCopyWith<$Res> {
  _$TransactionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amount = null,
    Object? categoryId = null,
    Object? accountId = null,
    Object? type = null,
    Object? note = freezed,
    Object? merchant = freezed,
    Object? destinationAccountId = freezed,
    Object? currency = null,
    Object? dateMillis = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            merchant: freezed == merchant
                ? _value.merchant
                : merchant // ignore: cast_nullable_to_non_nullable
                      as String?,
            destinationAccountId: freezed == destinationAccountId
                ? _value.destinationAccountId
                : destinationAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            dateMillis: null == dateMillis
                ? _value.dateMillis
                : dateMillis // ignore: cast_nullable_to_non_nullable
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
abstract class _$$TransactionDataImplCopyWith<$Res>
    implements $TransactionDataCopyWith<$Res> {
  factory _$$TransactionDataImplCopyWith(
    _$TransactionDataImpl value,
    $Res Function(_$TransactionDataImpl) then,
  ) = __$$TransactionDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    double amount,
    String categoryId,
    String accountId,
    String type,
    String? note,
    String? merchant,
    String? destinationAccountId,
    String currency,
    int dateMillis,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$TransactionDataImplCopyWithImpl<$Res>
    extends _$TransactionDataCopyWithImpl<$Res, _$TransactionDataImpl>
    implements _$$TransactionDataImplCopyWith<$Res> {
  __$$TransactionDataImplCopyWithImpl(
    _$TransactionDataImpl _value,
    $Res Function(_$TransactionDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransactionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amount = null,
    Object? categoryId = null,
    Object? accountId = null,
    Object? type = null,
    Object? note = freezed,
    Object? merchant = freezed,
    Object? destinationAccountId = freezed,
    Object? currency = null,
    Object? dateMillis = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$TransactionDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchant: freezed == merchant
            ? _value.merchant
            : merchant // ignore: cast_nullable_to_non_nullable
                  as String?,
        destinationAccountId: freezed == destinationAccountId
            ? _value.destinationAccountId
            : destinationAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        dateMillis: null == dateMillis
            ? _value.dateMillis
            : dateMillis // ignore: cast_nullable_to_non_nullable
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
class _$TransactionDataImpl implements _TransactionData {
  const _$TransactionDataImpl({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.type,
    this.note,
    this.merchant,
    this.destinationAccountId,
    this.currency = 'USD',
    required this.dateMillis,
    required this.createdAtMillis,
  });

  factory _$TransactionDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionDataImplFromJson(json);

  /// Duplicated for integrity check - must match row id
  @override
  final String id;

  /// Transaction amount (positive value)
  @override
  final double amount;

  /// Reference to the category
  @override
  final String categoryId;

  /// Reference to the account
  @override
  final String accountId;

  /// Transaction type: 'income' or 'expense'
  @override
  final String type;

  /// Optional note/memo for the transaction
  @override
  final String? note;

  /// Optional merchant/payee name
  @override
  final String? merchant;

  /// For transfers: the destination account ID
  @override
  final String? destinationAccountId;

  /// Currency code (default: USD)
  @override
  @JsonKey()
  final String currency;

  /// Matches the database date field for integrity verification during import.
  /// Not exported as a separate CSV column to avoid duplication.
  @override
  final int dateMillis;

  /// When the transaction was created (internal metadata only).
  /// Not exported as a separate CSV column to avoid duplication.
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'TransactionData(id: $id, amount: $amount, categoryId: $categoryId, accountId: $accountId, type: $type, note: $note, merchant: $merchant, destinationAccountId: $destinationAccountId, currency: $currency, dateMillis: $dateMillis, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.destinationAccountId, destinationAccountId) ||
                other.destinationAccountId == destinationAccountId) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.dateMillis, dateMillis) ||
                other.dateMillis == dateMillis) &&
            (identical(other.createdAtMillis, createdAtMillis) ||
                other.createdAtMillis == createdAtMillis));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    amount,
    categoryId,
    accountId,
    type,
    note,
    merchant,
    destinationAccountId,
    currency,
    dateMillis,
    createdAtMillis,
  );

  /// Create a copy of TransactionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionDataImplCopyWith<_$TransactionDataImpl> get copyWith =>
      __$$TransactionDataImplCopyWithImpl<_$TransactionDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionDataImplToJson(this);
  }
}

abstract class _TransactionData implements TransactionData {
  const factory _TransactionData({
    required final String id,
    required final double amount,
    required final String categoryId,
    required final String accountId,
    required final String type,
    final String? note,
    final String? merchant,
    final String? destinationAccountId,
    final String currency,
    required final int dateMillis,
    required final int createdAtMillis,
  }) = _$TransactionDataImpl;

  factory _TransactionData.fromJson(Map<String, dynamic> json) =
      _$TransactionDataImpl.fromJson;

  /// Duplicated for integrity check - must match row id
  @override
  String get id;

  /// Transaction amount (positive value)
  @override
  double get amount;

  /// Reference to the category
  @override
  String get categoryId;

  /// Reference to the account
  @override
  String get accountId;

  /// Transaction type: 'income' or 'expense'
  @override
  String get type;

  /// Optional note/memo for the transaction
  @override
  String? get note;

  /// Optional merchant/payee name
  @override
  String? get merchant;

  /// For transfers: the destination account ID
  @override
  String? get destinationAccountId;

  /// Currency code (default: USD)
  @override
  String get currency;

  /// Matches the database date field for integrity verification during import.
  /// Not exported as a separate CSV column to avoid duplication.
  @override
  int get dateMillis;

  /// When the transaction was created (internal metadata only).
  /// Not exported as a separate CSV column to avoid duplication.
  @override
  int get createdAtMillis;

  /// Create a copy of TransactionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionDataImplCopyWith<_$TransactionDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
