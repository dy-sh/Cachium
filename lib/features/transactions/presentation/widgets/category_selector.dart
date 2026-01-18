import 'package:flutter/material.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category.dart';

/// A widget for selecting a category from a list.
class CategorySelector extends StatefulWidget {
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
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
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
          child: Wrap(
            spacing: AppSpacing.chipGap,
            runSpacing: AppSpacing.chipGap,
            children: displayCategories.map((category) {
              final isSelected = category.id == widget.selectedId;
              return _CategoryChip(
                category: category,
                isSelected: isSelected,
                onTap: () {
                  HapticHelper.lightImpact();
                  widget.onChanged(category.id);
                },
              );
            }).toList(),
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
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectionGlow : AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected ? category.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: isSelected ? category.color : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              category.name,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? category.color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
