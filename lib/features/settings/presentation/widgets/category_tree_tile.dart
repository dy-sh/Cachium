import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../settings/data/models/app_settings.dart';

class CategoryTreeTile extends StatelessWidget {
  final CategoryTreeNode node;
  final ColorIntensity intensity;
  final bool isExpanded;
  final bool isDragging;
  final bool isDropTarget;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const CategoryTreeTile({
    super.key,
    required this.node,
    required this.intensity,
    this.isExpanded = false,
    this.isDragging = false,
    this.isDropTarget = false,
    this.onTap,
    this.onExpandToggle,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final category = node.category;
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = category.getColor(intensity);
    final indentation = node.depth * 24.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(
        left: indentation,
        bottom: AppSpacing.sm,
        right: 0,
      ),
      decoration: BoxDecoration(
        color: isDropTarget
            ? categoryColor.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDropTarget ? categoryColor : AppColors.border,
          width: isDropTarget ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isDragging ? 0.5 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Expand/collapse button for parent categories
                  if (node.hasChildren)
                    GestureDetector(
                      onTap: onExpandToggle,
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

                  // Category icon
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

                  // Category name and labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTypography.bodyMedium,
                        ),
                        if (!category.isCustom) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Default',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Drag handle
                  Icon(
                    LucideIcons.gripVertical,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DraggableCategoryTreeTile extends StatelessWidget {
  final CategoryTreeNode node;
  final ColorIntensity intensity;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;
  final Function(CategoryTreeNode)? onDragCompleted;

  const DraggableCategoryTreeTile({
    super.key,
    required this.node,
    required this.intensity,
    this.isExpanded = false,
    this.onTap,
    this.onExpandToggle,
    this.onDragCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<CategoryTreeNode>(
      data: node,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 48,
          child: CategoryTreeTile(
            node: node,
            intensity: intensity,
            isExpanded: false,
          ),
        ),
      ),
      childWhenDragging: CategoryTreeTile(
        node: node,
        intensity: intensity,
        isExpanded: isExpanded,
        isDragging: true,
        onTap: onTap,
        onExpandToggle: onExpandToggle,
      ),
      onDragCompleted: () => onDragCompleted?.call(node),
      child: CategoryTreeTile(
        node: node,
        intensity: intensity,
        isExpanded: isExpanded,
        onTap: onTap,
        onExpandToggle: onExpandToggle,
      ),
    );
  }
}
