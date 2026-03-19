// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttachmentDataImpl _$$AttachmentDataImplFromJson(Map<String, dynamic> json) =>
    _$AttachmentDataImpl(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      filePath: json['filePath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      createdAtMillis: (json['createdAtMillis'] as num).toInt(),
    );

Map<String, dynamic> _$$AttachmentDataImplToJson(
  _$AttachmentDataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'transactionId': instance.transactionId,
  'fileName': instance.fileName,
  'mimeType': instance.mimeType,
  'fileSize': instance.fileSize,
  'filePath': instance.filePath,
  'thumbnailPath': instance.thumbnailPath,
  'isEncrypted': instance.isEncrypted,
  'createdAtMillis': instance.createdAtMillis,
};
