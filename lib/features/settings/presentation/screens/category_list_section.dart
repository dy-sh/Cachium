import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/category_tree_tile.dart';
import '../widgets/category_drop_zone.dart';

/// Reorder hint bar displayed at the bottom of the category list.
class CategoryReorderHint extends ConsumerWidget {
  final CategoryTreeNode? draggedNode;
  final String? currentTargetParentId;

  const CategoryReorderHint({
    super.key,
    required this.draggedNode,
    required this.currentTargetParentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final isDragging = draggedNode != null;
    final parentCategory = currentTargetParentId != null
        ? ref.watch(categoryByIdProvider(currentTargetParentId!))
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: isDragging && parentCategory != null
          ? _buildParentIndicator(parentCategory, intensity)
          : isDragging
              ? _buildRootLevelIndicator()
              : _buildDefaultHint(),
    );
  }

  Widget _buildDefaultHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.gripVertical,
          size: 12,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          'Hold to reorder',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildRootLevelIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.home,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Root level',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildParentIndicator(Category parent, ColorIntensity intensity) {
    final parentColor = parent.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Inside',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: parentColor.withValues(alpha: bgOpacity),
            borderRadius: AppRadius.smAll,
            border: Border.all(color: parentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                parent.icon,
                size: 14,
                color: parentColor,
              ),
              const SizedBox(width: 6),
              Text(
                parent.name,
                style: AppTypography.labelSmall.copyWith(
                  color: parentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Root drop zone displayed at the top of the category list.
class CategoryRootDropZone extends ConsumerWidget {
  final ColorIntensity intensity;
  final void Function(bool isHovering) onHoverChanged;
  final void Function(CategoryTreeNode node) onAccept;

  const CategoryRootDropZone({
    super.key,
    required this.intensity,
    required this.onHoverChanged,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CategoryDropZone(
      label: 'Move to start',
      intensity: intensity,
      canAccept: (node) => true,
      onHoverChanged: (isHovering) => onHoverChanged(isHovering),
      onAccept: (node) => onAccept(node),
    );
  }
}

/// Add category tile displayed at the bottom of the category list.
class AddCategoryTile extends StatelessWidget {
  final VoidCallback onTap;

  const AddCategoryTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Add Category',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tree item in the category list with drag-and-drop support.
class CategoryTreeItem extends ConsumerWidget {
  final CategoryTreeNode node;
  final CategoryTreeNode? draggedNode;
  final ColorIntensity intensity;
  final bool isExpanded;
  final String? currentTargetParentId;
  final ValueNotifier<bool> showDragPlaceholderNotifier;
  final ValueNotifier<int> previewDepthNotifier;
  final VoidCallback onTap;
  final VoidCallback? onExpandToggle;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final void Function(Offset globalPosition) onDragUpdate;
  final void Function(CategoryTreeNode targetNode, int depth) onHoverChanged;
  final bool Function(CategoryTreeNode dragged, CategoryTreeNode target, int depth) canAccept;
  final void Function(CategoryTreeNode dragged, CategoryTreeNode target, int depth) onAccept;

  const CategoryTreeItem({
    super.key,
    required this.node,
    required this.draggedNode,
    required this.intensity,
    required this.isExpanded,
    required this.currentTargetParentId,
    required this.showDragPlaceholderNotifier,
    required this.previewDepthNotifier,
    required this.onTap,
    required this.onExpandToggle,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragUpdate,
    required this.onHoverChanged,
    required this.canAccept,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = draggedNode?.category.getColor(intensity) ??
                          node.category.getColor(intensity);

    final isThisTargetParent = currentTargetParentId != null &&
        currentTargetParentId == node.category.id;
    final draggedCategory = draggedNode?.category;
    final targetColor = draggedCategory?.getColor(intensity);

    // Suppress placeholder on the dragged item (childWhenDragging shows it instead)
    final isDraggedNode = draggedNode?.category.id == node.category.id;

    return CategoryItemDropTarget(
      targetNode: node,
      highlightColor: categoryColor,
      onHoverChanged: onHoverChanged,
      suppressPlaceholder: isDraggedNode,
      canAccept: canAccept,
      onAccept: onAccept,
      child: DraggableCategoryTreeTile(
        node: node,
        intensity: intensity,
        isExpanded: isExpanded,
        isTargetParent: isThisTargetParent,
        targetParentColor: targetColor,
        showDragPlaceholderNotifier: showDragPlaceholderNotifier,
        previewDepthNotifier: previewDepthNotifier,
        onTap: onTap,
        onExpandToggle: onExpandToggle,
        onDragStarted: onDragStarted,
        onDragEnd: onDragEnd,
        onDragUpdate: onDragUpdate,
      ),
    );
  }
}
