import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../settings/data/models/app_settings.dart';

/// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashLength = 6,
    this.gapLength = 4,
    this.borderRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    path.addRRect(rrect);

    // Create dashed path
    final dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashedPath = Path();
    final pathMetrics = source.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final segmentLength = draw ? dashLength : gapLength;
        final end = (distance + segmentLength).clamp(0.0, metric.length);

        if (draw) {
          final extractedPath = metric.extractPath(distance, end);
          dashedPath.addPath(extractedPath, Offset.zero);
        }

        distance = end;
        draw = !draw;
      }
    }

    return dashedPath;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashLength != oldDelegate.dashLength ||
      gapLength != oldDelegate.gapLength ||
      borderRadius != oldDelegate.borderRadius;
}

class CategoryTreeTile extends StatelessWidget {
  final CategoryTreeNode node;
  final ColorIntensity intensity;
  final bool isExpanded;
  final bool isDragging;
  final bool isDropTarget;
  final bool isTargetParent;
  final Color? targetParentColor;
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
    this.isTargetParent = false,
    this.targetParentColor,
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
    final highlightColor = targetParentColor ?? categoryColor;

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(
        left: indentation,
        bottom: AppSpacing.sm,
        right: 0,
      ),
      decoration: BoxDecoration(
        color: isDropTarget
            ? categoryColor.withOpacity(0.1)
            : isTargetParent
                ? highlightColor.withOpacity(0.08)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isTargetParent
            ? null // Use custom painter for dashed border
            : Border.all(
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
            opacity: isDragging ? 0.0 : 1.0,
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

    // Wrap with dashed border painter when this is the target parent
    if (isTargetParent) {
      return Stack(
        children: [
          container,
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(
                  left: indentation,
                  bottom: AppSpacing.sm,
                ),
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: highlightColor,
                    strokeWidth: 2,
                    dashLength: 6,
                    gapLength: 4,
                    borderRadius: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return container;
  }
}

class DraggableCategoryTreeTile extends StatelessWidget {
  final CategoryTreeNode node;
  final ColorIntensity intensity;
  final bool isExpanded;
  final bool isTargetParent;
  final Color? targetParentColor;
  final bool showDragPlaceholder; // Show placeholder at original position when dragging
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;
  final Function(CategoryTreeNode)? onDragCompleted;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final Function(Offset globalPosition)? onDragUpdate;

  const DraggableCategoryTreeTile({
    super.key,
    required this.node,
    required this.intensity,
    this.isExpanded = false,
    this.isTargetParent = false,
    this.targetParentColor,
    this.showDragPlaceholder = true,
    this.onTap,
    this.onExpandToggle,
    this.onDragCompleted,
    this.onDragStarted,
    this.onDragEnd,
    this.onDragUpdate,
  });

  Widget _buildDragPlaceholder(BuildContext context) {
    // Invisible spacer - just maintains height, no visuals at all
    return const SizedBox(height: 80); // 72 + 8 margin
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<CategoryTreeNode>(
      data: node,
      onDragStarted: onDragStarted,
      onDragUpdate: (details) => onDragUpdate?.call(details.globalPosition),
      onDragEnd: (_) => onDragEnd?.call(),
      onDraggableCanceled: (_, __) => onDragEnd?.call(),
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
      childWhenDragging: showDragPlaceholder
          ? _buildDragPlaceholder(context)
          : const SizedBox.shrink(),
      onDragCompleted: () {
        onDragEnd?.call();
        onDragCompleted?.call(node);
      },
      child: CategoryTreeTile(
        node: node,
        intensity: intensity,
        isExpanded: isExpanded,
        isTargetParent: isTargetParent,
        targetParentColor: targetParentColor,
        onTap: onTap,
        onExpandToggle: onExpandToggle,
      ),
    );
  }
}
