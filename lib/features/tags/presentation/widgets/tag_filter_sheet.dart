import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../providers/tags_provider.dart';
import 'tag_chip.dart';

/// Bottom sheet for filtering transactions by tags.
class TagFilterSheet extends ConsumerWidget {
  final Set<String> selectedTagIds;
  final ValueChanged<Set<String>> onChanged;

  const TagFilterSheet({
    super.key,
    required this.selectedTagIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final tags = tagsAsync.valueOrEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: AppRadius.smAll,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Filter by Tags', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          if (tags.isEmpty)
            Text(
              'No tags created yet',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: tags.map((tag) {
                final isSelected = selectedTagIds.contains(tag.id);
                return TagChip(
                  tag: tag,
                  selected: isSelected,
                  onTap: () {
                    final newIds = Set<String>.from(selectedTagIds);
                    if (isSelected) {
                      newIds.remove(tag.id);
                    } else {
                      newIds.add(tag.id);
                    }
                    onChanged(newIds);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (selectedTagIds.isNotEmpty)
            GestureDetector(
              onTap: () => onChanged({}),
              child: Text(
                'Clear all',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
