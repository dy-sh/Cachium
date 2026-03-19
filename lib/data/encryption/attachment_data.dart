import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment_data.freezed.dart';
part 'attachment_data.g.dart';

/// Internal data model for encrypted attachment metadata storage.
@freezed
class AttachmentData with _$AttachmentData {
  const factory AttachmentData({
    required String id,
    required String transactionId,
    required String fileName,
    required String mimeType,
    required int fileSize,
    required String filePath,
    String? thumbnailPath,
    @Default(false) bool isEncrypted,
    required int createdAtMillis,
  }) = _AttachmentData;

  factory AttachmentData.fromJson(Map<String, dynamic> json) =>
      _$AttachmentDataFromJson(json);
}
