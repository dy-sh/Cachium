import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../providers/tags_provider.dart';
import 'tag_chip.dart';

/// Multi-select tag chips for the transaction form.
class TagSelector extends ConsumerWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onChanged;

  const TagSelector({
    super.key,
    required this.selectedTagIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final tags = tagsAsync.valueOrEmpty;

    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: tags.map((tag) {
            final isSelected = selectedTagIds.contains(tag.id);
            return TagChip(
              tag: tag,
              selected: isSelected,
              onTap: () {
                final newIds = List<String>.from(selectedTagIds);
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
      ],
    );
  }
}
