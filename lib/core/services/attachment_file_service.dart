import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service for managing attachment files on disk.
class AttachmentFileService {
  static const _uuid = Uuid();
  static const _thumbWidth = 200;
  static const _attachmentsDir = 'attachments';
  static const _thumbsDir = 'attachments/thumbs';

  /// Save an image file and generate a thumbnail.
  /// Returns (filePath, thumbnailPath, fileSize).
  Future<({String filePath, String? thumbnailPath, int fileSize})>
      saveImage(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachDir = Directory('${appDir.path}/$_attachmentsDir');
    final thumbDir = Directory('${appDir.path}/$_thumbsDir');

    if (!attachDir.existsSync()) attachDir.createSync(recursive: true);
    if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);

    final ext = sourceFile.path.split('.').last.toLowerCase();
    final fileName = '${_uuid.v4()}.$ext';
    final destPath = '${attachDir.path}/$fileName';

    // Copy file
    await sourceFile.copy(destPath);
    final fileSize = await File(destPath).length();

    // Generate thumbnail
    String? thumbnailPath;
    try {
      final bytes = await sourceFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        final thumb = img.copyResize(image, width: _thumbWidth);
        final thumbBytes = img.encodeJpg(thumb, quality: 75);
        final thumbName = 'thumb_$fileName.jpg';
        thumbnailPath = '${thumbDir.path}/$thumbName';
        await File(thumbnailPath).writeAsBytes(thumbBytes);
      }
    } catch (_) {
      // Thumbnail generation failed — continue without it
    }

    return (
      filePath: destPath,
      thumbnailPath: thumbnailPath,
      fileSize: fileSize,
    );
  }

  /// Delete an attachment file and its thumbnail.
  Future<void> deleteFiles(String filePath, String? thumbnailPath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    if (thumbnailPath != null) {
      try {
        final thumb = File(thumbnailPath);
        if (await thumb.exists()) await thumb.delete();
      } catch (_) {}
    }
  }

  /// Get total storage used by attachments.
  Future<int> getTotalStorageUsed() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachDir = Directory('${appDir.path}/$_attachmentsDir');

    if (!attachDir.existsSync()) return 0;

    int total = 0;
    await for (final entity
        in attachDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
