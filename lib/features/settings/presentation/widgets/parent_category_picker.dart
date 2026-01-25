import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../providers/settings_provider.dart';

class ParentCategoryPicker extends ConsumerStatefulWidget {
  final CategoryType type;
  final String? currentCategoryId;
  final String? selectedParentId;
  final ValueChanged<String?> onSelected;

  const ParentCategoryPicker({
    super.key,
    required this.type,
    this.currentCategoryId,
    required this.selectedParentId,
    required this.onSelected,
  });

  @override
  ConsumerState<ParentCategoryPicker> createState() => _ParentCategoryPickerState();
}

class _ParentCategoryPickerState extends ConsumerState<ParentCategoryPicker> {
  final Set<String> _expandedIds = {};

  List<CategoryTreeNode> _buildVisibleNodes(List<CategoryTreeNode> tree, Set<String> excludedIds) {
    final result = <CategoryTreeNode>[];

    void addWithChildren(CategoryTreeNode node) {
      if (excludedIds.contains(node.category.id)) return;

      result.add(node);
      // Only add children if this node is expanded
      if (_expandedIds.contains(node.category.id)) {
        for (final child in node.children) {
          addWithChildren(child);
        }
      }
    }

    for (final node in tree) {
      addWithChildren(node);
    }

    return result;
  }

  bool _hasVisibleChildren(CategoryTreeNode node, Set<String> excludedIds) {
    for (final child in node.children) {
      if (!excludedIds.contains(child.category.id)) {
        return true;
      }
      if (_hasVisibleChildren(child, excludedIds)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrEmpty;
    final filteredCategories = categories.where((c) => c.type == widget.type).toList();
    final tree = CategoryTreeBuilder.buildTree(filteredCategories);

    final excludedIds = <String>{};
    if (widget.currentCategoryId != null) {
      excludedIds.add(widget.currentCategoryId!);
      excludedIds.addAll(
        CategoryTreeBuilder.getDescendantIds(categories, widget.currentCategoryId!),
      );
    }

    final visibleNodes = _buildVisibleNodes(tree, excludedIds);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Select Parent Category',
                  style: AppTypography.h4,
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // None option (root level)
                  _buildOptionTile(
                    context: context,
                    label: '(None - Root Level)',
                    isSelected: widget.selectedParentId == null,
                    onTap: () {
                      widget.onSelected(null);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Category tree
                  ...visibleNodes.map((node) {
                    final category = node.category;
                    final categoryColor = category.getColor(intensity);
                    final bgOpacity = AppColors.getBgOpacity(intensity);
                    final isSelected = widget.selectedParentId == category.id;
                    final indentation = node.depth * 24.0;
                    final hasChildren = _hasVisibleChildren(node, excludedIds);
                    final isExpanded = _expandedIds.contains(category.id);

                    return Padding(
                      padding: EdgeInsets.only(
                        left: indentation,
                        bottom: AppSpacing.sm,
                      ),
                      child: _buildCategoryOptionTile(
                        context: context,
                        category: category,
                        categoryColor: categoryColor,
                        bgOpacity: bgOpacity,
                        isSelected: isSelected,
                        hasChildren: hasChildren,
                        isExpanded: isExpanded,
                        onTap: () {
                          widget.onSelected(category.id);
                          Navigator.pop(context);
                        },
                        onToggleExpand: hasChildren
                            ? () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedIds.remove(category.id);
                                  } else {
                                    _expandedIds.add(category.id);
                                  }
                                });
                              }
                            : null,
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Spacer to align with category tiles that have expand button
            const SizedBox(width: 26),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.folderRoot,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.accentPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: AppColors.accentPrimary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOptionTile({
    required BuildContext context,
    required Category category,
    required Color categoryColor,
    required double bgOpacity,
    required bool isSelected,
    required bool hasChildren,
    required bool isExpanded,
    required VoidCallback onTap,
    VoidCallback? onToggleExpand,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? categoryColor.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? categoryColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Expand/collapse button
            if (hasChildren)
              GestureDetector(
                onTap: onToggleExpand,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 26),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(bgOpacity),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                size: 20,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                category.name,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? categoryColor : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: categoryColor,
              ),
          ],
        ),
      ),
    );
  }
}

void showParentCategoryPicker({
  required BuildContext context,
  required CategoryType type,
  String? currentCategoryId,
  required String? selectedParentId,
  required ValueChanged<String?> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.pop(ctx),
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => GestureDetector(
          onTap: () {}, // Prevent tap from propagating to parent
          child: ParentCategoryPicker(
            type: type,
            currentCategoryId: currentCategoryId,
            selectedParentId: selectedParentId,
            onSelected: onSelected,
          ),
        ),
      ),
    ),
  );
}
