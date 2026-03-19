import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/tag.dart';

/// A compact chip for displaying a tag.
class TagChip extends ConsumerWidget {
  final Tag tag;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool selected;

  const TagChip({
    super.key,
    required this.tag,
    this.onTap,
    this.onRemove,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final color = tag.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: bgOpacity * 2)
              : color.withValues(alpha: bgOpacity),
          borderRadius: AppRadius.smAll,
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tag.icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              tag.name,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
