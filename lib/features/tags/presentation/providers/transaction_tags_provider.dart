import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';

/// Provider that returns tag IDs for a given transaction.
final tagsForTransactionProvider =
    FutureProvider.family<List<String>, String>((ref, transactionId) async {
  final repo = ref.watch(tagRepositoryProvider);
  return repo.getTagIdsForTransaction(transactionId);
});

/// Provider that returns transaction IDs for a given tag.
final transactionsForTagProvider =
    FutureProvider.family<List<String>, String>((ref, tagId) async {
  final repo = ref.watch(tagRepositoryProvider);
  return repo.getTransactionIdsForTag(tagId);
});
