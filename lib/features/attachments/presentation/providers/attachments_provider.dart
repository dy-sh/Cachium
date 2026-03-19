import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/models/attachment.dart';

/// Provider that returns attachments for a given transaction.
final attachmentsForTransactionProvider =
    FutureProvider.family<List<Attachment>, String>((ref, transactionId) async {
  final repo = ref.watch(attachmentRepositoryProvider);
  return repo.getAttachmentsForTransaction(transactionId);
});

/// Provider for total storage used by attachments.
final attachmentStorageProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(attachmentRepositoryProvider);
  final attachments = await repo.getAllAttachments();
  int total = 0;
  for (final a in attachments) {
    total += a.fileSize;
  }
  return total;
});

/// Provider for attachment count.
final attachmentCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(attachmentRepositoryProvider);
  final attachments = await repo.getAllAttachments();
  return attachments.length;
});
