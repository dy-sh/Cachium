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

  void setShowAll(bool value) {
    _showAll = value;
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
  List<Category> getDisplayCategories(
    List<Category> categories, {
    CategorySortOption sortOption = CategorySortOption.listOrder,
    List<String>? recentCategoryIds,
  }) {
    final filtered = _viewingParentId == null
        ? categories.where((c) => c.parentId == null)
        : categories.where((c) => c.parentId == _viewingParentId);

    final result = filtered.toList();

    switch (sortOption) {
      case CategorySortOption.lastUsed:
        if (recentCategoryIds != null && recentCategoryIds.isNotEmpty) {
          // Sort by position in recentCategoryIds list
          result.sort((a, b) {
            final aIndex = recentCategoryIds.indexOf(a.id);
            final bIndex = recentCategoryIds.indexOf(b.id);
            // Categories not in list go to end, sorted by sortOrder
            if (aIndex == -1 && bIndex == -1) {
              return a.sortOrder.compareTo(b.sortOrder);
            }
            if (aIndex == -1) return 1;
            if (bIndex == -1) return -1;
            return aIndex.compareTo(bIndex);
          });
        } else {
          result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }
        break;
      case CategorySortOption.listOrder:
        result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case CategorySortOption.alphabetical:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return result;
  }
}

class CategorySelector extends ConsumerStatefulWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final int initialVisibleCount;
  final VoidCallback? onCreatePressed;
  final List<String>? recentCategoryIds;
  final CategorySortOption sortOption;

  const CategorySelector({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onChanged,
    this.initialVisibleCount = 6,
    this.onCreatePressed,
    this.recentCategoryIds,
    this.sortOption = CategorySortOption.lastUsed,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  final _navState = CategoryNavigationState();
  String? _lastSelectedId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch({bool collapse = false}) {
    _searchController.clear();
    _searchQuery = '';
    _searchFocusNode.unfocus();
    if (collapse) {
      _navState.setShowAll(false);
    }
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

    final bool isSearching = _searchQuery.isNotEmpty;

    final List<Category> displayCategories;
    if (isSearching) {
      // Flat search across ALL categories
      displayCategories = widget.categories
          .where((c) => c.name.toLowerCase().contains(_searchQuery))
          .toList();
    } else {
      // Normal hierarchy navigation
      displayCategories = _navState.getDisplayCategories(
        widget.categories,
        sortOption: widget.sortOption,
        recentCategoryIds: widget.recentCategoryIds,
      );
    }
    final hasMore = displayCategories.length > widget.initialVisibleCount;

    // Build grid items similar to AccountSelector
    final List<_GridItem> gridItems = [];

    if (_navState.showAll || !hasMore) {
      // Show all categories
      for (final category in displayCategories) {
        gridItems.add(_GridItem.category(category));
      }
      // Add create button when expanded or when few categories
      if (widget.onCreatePressed != null) {
        gridItems.add(_GridItem.create());
      }
    } else {
      // Show limited categories + "More" button
      for (int i = 0; i < widget.initialVisibleCount; i++) {
        gridItems.add(_GridItem.category(displayCategories[i]));
      }
      gridItems.add(_GridItem.more(displayCategories.length - widget.initialVisibleCount));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show search field when expanded
        if (_navState.showAll) ...[
          InputField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hint: 'Search categories...',
            prefix: Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
            suffix: GestureDetector(
              onTap: () => setState(() => _clearSearch(collapse: true)),
              child: Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
            ),
            showClearButton: false,
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Navigation header when viewing children (hide during search)
        if (!_navState.isAtRoot && !isSearching) ...[
          _buildNavigationHeader(intensity),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Selected parent indicator (hide during search)
        if (!_navState.isAtRoot && !isSearching) ...[
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
            itemCount: gridItems.length,
            itemBuilder: (context, index) {
              final item = gridItems[index];
              switch (item.type) {
                case _GridItemType.category:
                  final category = item.category!;
                  final isSelected = category.id == widget.selectedId;
                  final hasChildren = ref.watch(hasChildrenProvider(category.id));
                  return _CategoryChip(
                    category: category,
                    isSelected: isSelected,
                    hasChildren: hasChildren,
                    intensity: intensity,
                    onTap: () => _handleCategoryTap(category, hasChildren),
                  );
                case _GridItemType.more:
                  return _MoreChip(
                    count: item.moreCount!,
                    onTap: () => setState(() => _navState.setShowAll(true)),
                  );
                case _GridItemType.create:
                  return _CreateNewChip(onTap: widget.onCreatePressed!);
              }
            },
          ),
        ),
        if (_navState.showAll && hasMore) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() {
              _navState.setShowAll(false);
              _clearSearch();
            }),
            child: Text(
              'Show Less',
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
    final wasSearching = _searchQuery.isNotEmpty;
    _lastSelectedId = category.id;
    widget.onChanged(category.id);

    setState(() {
      // Clear search and unfocus when selecting a category
      _clearSearch();

      if (wasSearching && category.parentId != null) {
        // When selecting from search, navigate to show parent level (siblings visible)
        final ancestors = ref.read(categoryAncestorsProvider(category.id));
        _navState.initializeFor(widget.categories, category.id, ancestors);
      } else if (hasChildren) {
        _navState.navigateTo(category.id);
      }
    });
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

enum _GridItemType { category, more, create }

class _GridItem {
  final _GridItemType type;
  final Category? category;
  final int? moreCount;

  _GridItem._({required this.type, this.category, this.moreCount});

  factory _GridItem.category(Category category) =>
      _GridItem._(type: _GridItemType.category, category: category);

  factory _GridItem.more(int count) =>
      _GridItem._(type: _GridItemType.more, moreCount: count);

  factory _GridItem.create() => _GridItem._(type: _GridItemType.create);
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

class _MoreChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MoreChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticHelper.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                LucideIcons.moreHorizontal,
                size: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '+$count',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
