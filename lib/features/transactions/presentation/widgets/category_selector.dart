import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class CategorySelector extends ConsumerStatefulWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final int initialVisibleCount;
  final VoidCallback? onCreatePressed;

  const CategorySelector({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onChanged,
    this.initialVisibleCount = 9,
    this.onCreatePressed,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  bool _showAll = false;
  String? _viewingParentId;
  final List<String> _navigationStack = [];

  @override
  void initState() {
    super.initState();
    if (widget.selectedId != null) {
      _initializeViewingState();
    }
  }

  void _initializeViewingState() {
    final selectedCategory = widget.categories.firstWhere(
      (c) => c.id == widget.selectedId,
      orElse: () => widget.categories.first,
    );

    if (selectedCategory.parentId != null) {
      final ancestors = ref.read(categoryAncestorsProvider(widget.selectedId!));
      _navigationStack.addAll(ancestors.map((c) => c.id));
      _viewingParentId = selectedCategory.parentId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);

    // Show empty state if no categories available
    if (widget.categories.isEmpty) {
      return _buildEmptyState();
    }

    final displayCategories = _getDisplayCategories();
    final hasMore = displayCategories.length > widget.initialVisibleCount;
    final visibleCategories = _showAll || !hasMore
        ? displayCategories
        : displayCategories.take(widget.initialVisibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation header when viewing children
        if (_viewingParentId != null) ...[
          _buildNavigationHeader(intensity),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Selected parent indicator
        if (_viewingParentId != null) ...[
          _buildSelectedParentIndicator(intensity),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Category grid
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
            itemCount: visibleCategories.length,
            itemBuilder: (context, index) {
              final category = visibleCategories[index];
              final isSelected = category.id == widget.selectedId;
              final hasChildren = ref.watch(hasChildrenProvider(category.id));
              return _CategoryChip(
                category: category,
                isSelected: isSelected,
                hasChildren: hasChildren,
                intensity: intensity,
                onTap: () => _handleCategoryTap(category, hasChildren),
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

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: widget.onCreatePressed,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          color: AppColors.expense.withOpacity(0.08),
          border: Border.all(
            color: AppColors.expense.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.expense.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.folderPlus,
                size: 18,
                color: AppColors.expense,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No categories available',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to create a category',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.expense.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.expense.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  List<Category> _getDisplayCategories() {
    if (_viewingParentId == null) {
      return widget.categories
          .where((c) => c.parentId == null)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } else {
      return widget.categories
          .where((c) => c.parentId == _viewingParentId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
  }

  void _handleCategoryTap(Category category, bool hasChildren) {
    HapticHelper.lightImpact();

    widget.onChanged(category.id);

    if (hasChildren) {
      setState(() {
        _navigationStack.add(category.id);
        _viewingParentId = category.id;
        _showAll = false;
      });
    }
  }

  void _navigateBack() {
    HapticHelper.lightImpact();
    setState(() {
      if (_navigationStack.isNotEmpty) {
        _navigationStack.removeLast();
        _viewingParentId = _navigationStack.isNotEmpty ? _navigationStack.last : null;
      } else {
        _viewingParentId = null;
      }
      _showAll = false;
    });
  }

  Widget _buildNavigationHeader(ColorIntensity intensity) {
    return GestureDetector(
      onTap: _navigateBack,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              LucideIcons.arrowLeft,
              size: 16,
              color: AppColors.accentPrimary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _navigationStack.length > 1
                  ? 'Back to ${_getPreviousParentName()}'
                  : 'Back to All Categories',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviousParentName() {
    if (_navigationStack.length < 2) return 'All Categories';

    final previousParentId = _navigationStack[_navigationStack.length - 2];
    final previousParent = widget.categories.firstWhere(
      (c) => c.id == previousParentId,
      orElse: () => widget.categories.first,
    );
    return previousParent.name;
  }

  Widget _buildSelectedParentIndicator(ColorIntensity intensity) {
    final parentCategory = widget.categories.firstWhere(
      (c) => c.id == _viewingParentId,
      orElse: () => widget.categories.first,
    );

    final isParentSelected = widget.selectedId == _viewingParentId;
    final categoryColor = parentCategory.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.smAll,
        gradient: isParentSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withOpacity(bgOpacity * 0.4),
                  categoryColor.withOpacity(bgOpacity * 0.2),
                ],
              )
            : null,
        color: isParentSelected ? null : AppColors.surface,
        border: Border.all(
          color: isParentSelected ? categoryColor : AppColors.border,
          width: isParentSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isParentSelected
                  ? categoryColor.withOpacity(0.9)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              parentCategory.icon,
              size: 12,
              color: isParentSelected ? AppColors.background : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            parentCategory.name,
            style: AppTypography.labelSmall.copyWith(
              color: isParentSelected ? categoryColor : AppColors.textPrimary,
              fontWeight: isParentSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (isParentSelected) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              LucideIcons.check,
              size: 14,
              color: categoryColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final bool hasChildren;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.hasChildren,
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
            if (hasChildren) ...[
              const SizedBox(width: 2),
              Icon(
                LucideIcons.chevronRight,
                size: 12,
                color: isSelected ? categoryColor : AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
