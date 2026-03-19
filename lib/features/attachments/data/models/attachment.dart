class Attachment {
  final String id;
  final String transactionId;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String filePath;
  final String? thumbnailPath;
  final bool isEncrypted;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.transactionId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.filePath,
    this.thumbnailPath,
    this.isEncrypted = false,
    required this.createdAt,
  });

  Attachment copyWith({
    String? id,
    String? transactionId,
    String? fileName,
    String? mimeType,
    int? fileSize,
    String? filePath,
    String? thumbnailPath,
    bool? isEncrypted,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attachment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
