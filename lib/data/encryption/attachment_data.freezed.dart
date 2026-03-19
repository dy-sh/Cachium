// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AttachmentData _$AttachmentDataFromJson(Map<String, dynamic> json) {
  return _AttachmentData.fromJson(json);
}

/// @nodoc
mixin _$AttachmentData {
  String get id => throw _privateConstructorUsedError;
  String get transactionId => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  String get mimeType => throw _privateConstructorUsedError;
  int get fileSize => throw _privateConstructorUsedError;
  String get filePath => throw _privateConstructorUsedError;
  String? get thumbnailPath => throw _privateConstructorUsedError;
  bool get isEncrypted => throw _privateConstructorUsedError;
  int get createdAtMillis => throw _privateConstructorUsedError;

  /// Serializes this AttachmentData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AttachmentData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttachmentDataCopyWith<AttachmentData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttachmentDataCopyWith<$Res> {
  factory $AttachmentDataCopyWith(
    AttachmentData value,
    $Res Function(AttachmentData) then,
  ) = _$AttachmentDataCopyWithImpl<$Res, AttachmentData>;
  @useResult
  $Res call({
    String id,
    String transactionId,
    String fileName,
    String mimeType,
    int fileSize,
    String filePath,
    String? thumbnailPath,
    bool isEncrypted,
    int createdAtMillis,
  });
}

/// @nodoc
class _$AttachmentDataCopyWithImpl<$Res, $Val extends AttachmentData>
    implements $AttachmentDataCopyWith<$Res> {
  _$AttachmentDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttachmentData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? transactionId = null,
    Object? fileName = null,
    Object? mimeType = null,
    Object? fileSize = null,
    Object? filePath = null,
    Object? thumbnailPath = freezed,
    Object? isEncrypted = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            transactionId: null == transactionId
                ? _value.transactionId
                : transactionId // ignore: cast_nullable_to_non_nullable
                      as String,
            fileName: null == fileName
                ? _value.fileName
                : fileName // ignore: cast_nullable_to_non_nullable
                      as String,
            mimeType: null == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String,
            fileSize: null == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                      as int,
            filePath: null == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbnailPath: freezed == thumbnailPath
                ? _value.thumbnailPath
                : thumbnailPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            isEncrypted: null == isEncrypted
                ? _value.isEncrypted
                : isEncrypted // ignore: cast_nullable_to_non_nullable
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
abstract class _$$AttachmentDataImplCopyWith<$Res>
    implements $AttachmentDataCopyWith<$Res> {
  factory _$$AttachmentDataImplCopyWith(
    _$AttachmentDataImpl value,
    $Res Function(_$AttachmentDataImpl) then,
  ) = __$$AttachmentDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String transactionId,
    String fileName,
    String mimeType,
    int fileSize,
    String filePath,
    String? thumbnailPath,
    bool isEncrypted,
    int createdAtMillis,
  });
}

/// @nodoc
class __$$AttachmentDataImplCopyWithImpl<$Res>
    extends _$AttachmentDataCopyWithImpl<$Res, _$AttachmentDataImpl>
    implements _$$AttachmentDataImplCopyWith<$Res> {
  __$$AttachmentDataImplCopyWithImpl(
    _$AttachmentDataImpl _value,
    $Res Function(_$AttachmentDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AttachmentData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? transactionId = null,
    Object? fileName = null,
    Object? mimeType = null,
    Object? fileSize = null,
    Object? filePath = null,
    Object? thumbnailPath = freezed,
    Object? isEncrypted = null,
    Object? createdAtMillis = null,
  }) {
    return _then(
      _$AttachmentDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        transactionId: null == transactionId
            ? _value.transactionId
            : transactionId // ignore: cast_nullable_to_non_nullable
                  as String,
        fileName: null == fileName
            ? _value.fileName
            : fileName // ignore: cast_nullable_to_non_nullable
                  as String,
        mimeType: null == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String,
        fileSize: null == fileSize
            ? _value.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int,
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbnailPath: freezed == thumbnailPath
            ? _value.thumbnailPath
            : thumbnailPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        isEncrypted: null == isEncrypted
            ? _value.isEncrypted
            : isEncrypted // ignore: cast_nullable_to_non_nullable
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
class _$AttachmentDataImpl implements _AttachmentData {
  const _$AttachmentDataImpl({
    required this.id,
    required this.transactionId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.filePath,
    this.thumbnailPath,
    this.isEncrypted = false,
    required this.createdAtMillis,
  });

  factory _$AttachmentDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttachmentDataImplFromJson(json);

  @override
  final String id;
  @override
  final String transactionId;
  @override
  final String fileName;
  @override
  final String mimeType;
  @override
  final int fileSize;
  @override
  final String filePath;
  @override
  final String? thumbnailPath;
  @override
  @JsonKey()
  final bool isEncrypted;
  @override
  final int createdAtMillis;

  @override
  String toString() {
    return 'AttachmentData(id: $id, transactionId: $transactionId, fileName: $fileName, mimeType: $mimeType, fileSize: $fileSize, filePath: $filePath, thumbnailPath: $thumbnailPath, isEncrypted: $isEncrypted, createdAtMillis: $createdAtMillis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttachmentDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.isEncrypted, isEncrypted) ||
                other.isEncrypted == isEncrypted) &&
            (identical(other.createdAtMillis, createdAtMillis) ||
                other.createdAtMillis == createdAtMillis));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    transactionId,
    fileName,
    mimeType,
    fileSize,
    filePath,
    thumbnailPath,
    isEncrypted,
    createdAtMillis,
  );

  /// Create a copy of AttachmentData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttachmentDataImplCopyWith<_$AttachmentDataImpl> get copyWith =>
      __$$AttachmentDataImplCopyWithImpl<_$AttachmentDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AttachmentDataImplToJson(this);
  }
}

abstract class _AttachmentData implements AttachmentData {
  const factory _AttachmentData({
    required final String id,
    required final String transactionId,
    required final String fileName,
    required final String mimeType,
    required final int fileSize,
    required final String filePath,
    final String? thumbnailPath,
    final bool isEncrypted,
    required final int createdAtMillis,
  }) = _$AttachmentDataImpl;

  factory _AttachmentData.fromJson(Map<String, dynamic> json) =
      _$AttachmentDataImpl.fromJson;

  @override
  String get id;
  @override
  String get transactionId;
  @override
  String get fileName;
  @override
  String get mimeType;
  @override
  int get fileSize;
  @override
  String get filePath;
  @override
  String? get thumbnailPath;
  @override
  bool get isEncrypted;
  @override
  int get createdAtMillis;

  /// Create a copy of AttachmentData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttachmentDataImplCopyWith<_$AttachmentDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
