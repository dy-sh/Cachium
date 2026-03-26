import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/optimistic_notifier.dart';
import '../../data/models/tag.dart';

class TagsNotifier extends AsyncNotifier<List<Tag>>
    with OptimisticAsyncNotifier<Tag> {
  @override
  Future<List<Tag>> build() async {
    final repo = ref.watch(tagRepositoryProvider);
    return repo.getAllTags();
  }

  Future<void> addTag(Tag tag) => runOptimistic(
        update: (tags) => [...tags, tag],
        action: () => ref.read(tagRepositoryProvider).createTag(tag),
        onError: (e) =>
            RepositoryException.create(entityType: 'Tag', cause: e),
      );

  Future<void> updateTag(Tag tag) => runOptimistic(
        update: (tags) =>
            tags.map((t) => t.id == tag.id ? tag : t).toList(),
        action: () => ref.read(tagRepositoryProvider).updateTag(tag),
        onError: (e) => RepositoryException.update(
            entityType: 'Tag', entityId: tag.id, cause: e),
      );

  Future<void> deleteTag(String id) => runOptimistic(
        update: (tags) => tags.where((t) => t.id != id).toList(),
        action: () => ref.read(tagRepositoryProvider).deleteTag(id),
        onError: (e) => RepositoryException.delete(
            entityType: 'Tag', entityId: id, cause: e),
      );

  Future<void> reorderTag(String tagId, int newSortOrder) async {
    final tags = state.valueOrNull;
    if (tags == null) return;

    final tag = tags.firstWhere((t) => t.id == tagId);
    final updated = tag.copyWith(sortOrder: newSortOrder);

    return runOptimistic(
      update: (tags) =>
          tags.map((t) => t.id == tagId ? updated : t).toList(),
      action: () => ref.read(tagRepositoryProvider).updateTag(updated),
      onError: (e) => RepositoryException.update(
          entityType: 'Tag', entityId: tagId, cause: e),
    );
  }

  Future<void> refresh() async {
    try {
      final repo = ref.read(tagRepositoryProvider);
      state = AsyncData(await repo.getAllTags());
    } catch (e, st) {
      state = AsyncError(
        e is AppException
            ? e
            : RepositoryException.fetch(entityType: 'Tag', cause: e),
        st,
      );
    }
  }
}

final tagsProvider = AsyncNotifierProvider<TagsNotifier, List<Tag>>(() {
  return TagsNotifier();
});

/// Computed map for O(1) tag lookups.
final tagMapProvider = Provider<Map<String, Tag>>((ref) {
  final tagsAsync = ref.watch(tagsProvider);
  final tags = tagsAsync.valueOrNull;
  if (tags == null) return {};
  return {for (final t in tags) t.id: t};
});

final tagByIdProvider = Provider.family<Tag?, String>((ref, id) {
  return ref.watch(tagMapProvider)[id];
});

/// Checks if a tag name already exists (case-insensitive).
final tagNameExistsProvider =
    Provider.family<bool, ({String name, String? excludeId})>((ref, params) {
  final tagsAsync = ref.watch(tagsProvider);
  final tags = tagsAsync.valueOrNull ?? [];
  final nameLower = params.name.trim().toLowerCase();
  return tags.any(
      (t) => t.name.toLowerCase() == nameLower && t.id != params.excludeId);
});
