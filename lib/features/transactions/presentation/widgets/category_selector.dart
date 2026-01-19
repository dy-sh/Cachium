import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// A widget for selecting a category from a list.
class CategorySelector extends ConsumerStatefulWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final int initialVisibleCount;

  const CategorySelector({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onChanged,
    this.initialVisibleCount = 9,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final hasMore = widget.categories.length > widget.initialVisibleCount;
    final displayCategories = _showAll || !hasMore
        ? widget.categories
        : widget.categories.take(widget.initialVisibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: AppAnimations.slow,
          curve: AppAnimations.defaultCurve,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.4,
              crossAxisSpacing: AppSpacing.chipGap,
              mainAxisSpacing: AppSpacing.chipGap,
            ),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              final isSelected = category.id == widget.selectedId;
              return _CategoryChip(
                category: category,
                isSelected: isSelected,
                intensity: intensity,
                onTap: () {
                  HapticHelper.lightImpact();
                  widget.onChanged(category.id);
                },
              );
            },
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll ? 'Show Less' : 'Show All',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = category.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smAll,
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withOpacity(bgOpacity * 0.4),
                    categoryColor.withOpacity(bgOpacity * 0.2),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.surface,
          border: Border.all(
            color: isSelected ? categoryColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? categoryColor.withOpacity(0.9)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                category.icon,
                size: 12,
                color: isSelected ? AppColors.background : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                category.name,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? categoryColor : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
