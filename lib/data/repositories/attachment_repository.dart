import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/attachments/data/models/attachment.dart' as ui;
import '../encryption/attachment_data.dart';

/// Repository for managing encrypted attachment metadata storage.
class AttachmentRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'Attachment';

  AttachmentRepository({
    required this.database,
    required this.encryptionService,
  });

  AttachmentData _toData(ui.Attachment attachment) {
    return AttachmentData(
      id: attachment.id,
      transactionId: attachment.transactionId,
      fileName: attachment.fileName,
      mimeType: attachment.mimeType,
      fileSize: attachment.fileSize,
      filePath: attachment.filePath,
      thumbnailPath: attachment.thumbnailPath,
      isEncrypted: attachment.isEncrypted,
      createdAtMillis: attachment.createdAt.millisecondsSinceEpoch,
    );
  }

  ui.Attachment _toAttachment(AttachmentData data) {
    return ui.Attachment(
      id: data.id,
      transactionId: data.transactionId,
      fileName: data.fileName,
      mimeType: data.mimeType,
      fileSize: data.fileSize,
      filePath: data.filePath,
      thumbnailPath: data.thumbnailPath,
      isEncrypted: data.isEncrypted,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  Future<void> createAttachment(ui.Attachment attachment) async {
    try {
      final data = _toData(attachment);
      final encryptedBlob = await encryptionService.encryptAttachment(data);

      await database.insertAttachment(
        id: attachment.id,
        transactionId: attachment.transactionId,
        createdAt: attachment.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<ui.Attachment?> getAttachment(String id) async {
    final row = await database.getAttachment(id);
    if (row == null) return null;

    try {
      final data = await encryptionService.decryptAttachment(
        row.encryptedBlob,
        expectedId: row.id,
      );
      return _toAttachment(data);
    } catch (e) {
      throw RepositoryException.decryption(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  Future<List<ui.Attachment>> getAttachmentsForTransaction(
      String transactionId) async {
    try {
      final rows =
          await database.getAttachmentsByTransactionId(transactionId);

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final data = await encryptionService.decryptAttachment(
              row.encryptedBlob,
              expectedId: row.id,
            );
            return _toAttachment(data);
          } catch (e) {
            debugPrint('WARNING: Corrupted attachment row id=${row.id}: $e');
            return null;
          }
        }),
      );

      return results.whereType<ui.Attachment>().toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  Future<List<ui.Attachment>> getAllAttachments() async {
    try {
      final rows = await database.getAllAttachments();

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final data = await encryptionService.decryptAttachment(
              row.encryptedBlob,
              expectedId: row.id,
            );
            return _toAttachment(data);
          } catch (e) {
            debugPrint('WARNING: Corrupted attachment row id=${row.id}: $e');
            return null;
          }
        }),
      );

      return results.whereType<ui.Attachment>().toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  Future<void> deleteAttachment(String id) async {
    try {
      await database.softDeleteAttachment(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw RepositoryException.delete(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  Stream<List<ui.Attachment>> watchAttachmentsForTransaction(
      String transactionId) {
    return database
        .watchAttachmentsByTransactionId(transactionId)
        .asyncMap((rows) async {
      final results = await Future.wait(
        rows.map((row) async {
          try {
            final data = await encryptionService.decryptAttachment(
              row.encryptedBlob,
              expectedId: row.id,
            );
            return _toAttachment(data);
          } catch (e) {
            debugPrint('WARNING: Corrupted attachment row id=${row.id}: $e');
            return null;
          }
        }),
      );
      final attachments = results.whereType<ui.Attachment>().toList();
      return attachments;
    });
  }
}
