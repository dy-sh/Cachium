import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Encapsulates category tree navigation state.
///
/// Manages the navigation stack for drilling into category hierarchies,
/// tracking which parent category is being viewed and the path back to root.
class CategoryNavigationState {
  final List<String> _navigationStack = [];
  String? _viewingParentId;
  bool _showAll = false;

  String? get viewingParentId => _viewingParentId;
  bool get showAll => _showAll;
  bool get isAtRoot => _viewingParentId == null;

  /// Initialize navigation to show a selected category's parent level.
  void initializeFor(List<Category> categories, String? selectedId, List<Category> ancestors) {
    // Reset state first
    _navigationStack.clear();
    _viewingParentId = null;
    _showAll = false;

    if (selectedId == null || categories.isEmpty) return;

    final selectedCategory = categories.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => categories.first,
    );

    if (selectedCategory.parentId != null) {
      _navigationStack.addAll(ancestors.map((c) => c.id));
      _viewingParentId = selectedCategory.parentId;
    }
  }

  /// Navigate into a category to view its children.
  void navigateTo(String categoryId) {
    _navigationStack.add(categoryId);
    _viewingParentId = categoryId;
    _showAll = false;
  }

  /// Navigate back to the previous level.
  void navigateBack() {
    if (_navigationStack.isNotEmpty) {
      _navigationStack.removeLast();
      _viewingParentId = _navigationStack.isNotEmpty ? _navigationStack.last : null;
    } else {
      _viewingParentId = null;
    }
    _showAll = false;
  }

  /// Toggle show all categories.
  void toggleShowAll() {
    _showAll = !_showAll;
  }

  /// Get the name of the previous parent in the navigation stack.
  String getPreviousParentName(List<Category> categories) {
    if (_navigationStack.length < 2) return 'All Categories';

    final previousParentId = _navigationStack[_navigationStack.length - 2];
    final previousParent = categories.firstWhere(
      (c) => c.id == previousParentId,
      orElse: () => categories.first,
    );
    return previousParent.name;
  }

  /// Get categories to display at the current navigation level.
  List<Category> getDisplayCategories(List<Category> categories) {
    final filtered = _viewingParentId == null
        ? categories.where((c) => c.parentId == null)
        : categories.where((c) => c.parentId == _viewingParentId);
    return filtered.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}

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
  final _navState = CategoryNavigationState();
  String? _lastSelectedId;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void didUpdateWidget(CategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize navigation when selected category changes externally
    // (e.g., after creating a new child category)
    if (widget.selectedId != oldWidget.selectedId &&
        widget.selectedId != _lastSelectedId) {
      _initializeNavigation();
    }
  }

  void _initializeNavigation() {
    if (widget.selectedId != null && widget.categories.isNotEmpty) {
      final ancestors = ref.read(categoryAncestorsProvider(widget.selectedId!));
      _navState.initializeFor(widget.categories, widget.selectedId, ancestors);
      _lastSelectedId = widget.selectedId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);

    // Show empty state if no categories available
    if (widget.categories.isEmpty) {
      return EmptyState(
        icon: LucideIcons.folderPlus,
        title: 'No categories available',
        subtitle: 'Tap to create a category',
        onTap: widget.onCreatePressed,
      );
    }

    final displayCategories = _navState.getDisplayCategories(widget.categories);
    final hasMore = displayCategories.length > widget.initialVisibleCount;
    final visibleCategories = _navState.showAll || !hasMore
        ? displayCategories
        : displayCategories.take(widget.initialVisibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation header when viewing children
        if (!_navState.isAtRoot) ...[
          _buildNavigationHeader(intensity),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Selected parent indicator
        if (!_navState.isAtRoot) ...[
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
            // Add 1 for the "Create new" button
            itemCount: visibleCategories.length + (widget.onCreatePressed != null ? 1 : 0),
            itemBuilder: (context, index) {
              // Last item is the "Create new" button
              if (index == visibleCategories.length && widget.onCreatePressed != null) {
                return _CreateNewChip(onTap: widget.onCreatePressed!);
              }
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
            onTap: () => setState(() => _navState.toggleShowAll()),
            child: Text(
              _navState.showAll ? 'Show Less' : 'Show All',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleCategoryTap(Category category, bool hasChildren) {
    HapticHelper.lightImpact();
    _lastSelectedId = category.id;
    widget.onChanged(category.id);

    if (hasChildren) {
      setState(() => _navState.navigateTo(category.id));
    }
  }

  void _navigateBack() {
    HapticHelper.lightImpact();
    setState(() => _navState.navigateBack());
  }

  Widget _buildNavigationHeader(ColorIntensity intensity) {
    final backLabel = _navState.getPreviousParentName(widget.categories);
    final isAtTop = backLabel == 'All Categories';

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
              isAtTop ? 'Back to All Categories' : 'Back to $backLabel',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedParentIndicator(ColorIntensity intensity) {
    final parentCategory = widget.categories.firstWhere(
      (c) => c.id == _navState.viewingParentId,
      orElse: () => widget.categories.first,
    );

    final isParentSelected = widget.selectedId == _navState.viewingParentId;
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

    return SelectableCard(
      isSelected: isSelected,
      color: categoryColor,
      bgOpacity: bgOpacity,
      icon: category.icon,
      onTap: onTap,
      content: Text(
        category.name,
        style: AppTypography.labelSmall.copyWith(
          color: isSelected ? categoryColor : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: hasChildren
          ? Icon(
              LucideIcons.chevronRight,
              size: 12,
              color: isSelected ? categoryColor : AppColors.textTertiary,
            )
          : null,
    );
  }
}

class _CreateNewChip extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateNewChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.3),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: 14,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'New',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
