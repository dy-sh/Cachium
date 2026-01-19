import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../settings/data/models/app_settings.dart';

class CategoryDropZone extends StatefulWidget {
  final String label;
  final ColorIntensity intensity;
  final bool Function(CategoryTreeNode) canAccept;
  final void Function(CategoryTreeNode) onAccept;
  final double? leftPadding;

  const CategoryDropZone({
    super.key,
    required this.label,
    required this.intensity,
    required this.canAccept,
    required this.onAccept,
    this.leftPadding,
  });

  @override
  State<CategoryDropZone> createState() => _CategoryDropZoneState();
}

class _CategoryDropZoneState extends State<CategoryDropZone> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<CategoryTreeNode>(
      onWillAcceptWithDetails: (details) {
        final canAccept = widget.canAccept(details.data);
        if (canAccept && !_isHovering) {
          setState(() => _isHovering = true);
        }
        return canAccept;
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onAccept(details.data);
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(
            left: widget.leftPadding ?? 0,
            bottom: AppSpacing.sm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _isHovering
                ? AppColors.accentPrimary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovering
                  ? AppColors.accentPrimary
                  : AppColors.border.withValues(alpha: 0.5),
              width: _isHovering ? 2 : 1,
              style: _isHovering ? BorderStyle.solid : BorderStyle.none,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isHovering ? 1.0 : 0.0,
            child: Center(
              child: Text(
                widget.label,
                style: AppTypography.bodySmall.copyWith(
                  color: _isHovering
                      ? AppColors.accentPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum DropZone { none, top, center, bottom }

class CategoryItemDropTarget extends StatefulWidget {
  final Widget child;
  final CategoryTreeNode targetNode;
  final bool Function(CategoryTreeNode dragged, CategoryTreeNode target) canAcceptAsChild;
  final bool Function(CategoryTreeNode dragged, CategoryTreeNode target) canAcceptBefore;
  final bool Function(CategoryTreeNode dragged, CategoryTreeNode target) canAcceptAfter;
  final void Function(CategoryTreeNode dragged, CategoryTreeNode target) onAcceptAsChild;
  final void Function(CategoryTreeNode dragged, CategoryTreeNode target) onAcceptBefore;
  final void Function(CategoryTreeNode dragged, CategoryTreeNode target) onAcceptAfter;
  final Color? highlightColor;

  const CategoryItemDropTarget({
    super.key,
    required this.child,
    required this.targetNode,
    required this.canAcceptAsChild,
    required this.canAcceptBefore,
    required this.canAcceptAfter,
    required this.onAcceptAsChild,
    required this.onAcceptBefore,
    required this.onAcceptAfter,
    this.highlightColor,
  });

  @override
  State<CategoryItemDropTarget> createState() => _CategoryItemDropTargetState();
}

class _CategoryItemDropTargetState extends State<CategoryItemDropTarget> {
  DropZone _currentZone = DropZone.none;
  final GlobalKey _key = GlobalKey();

  // Estimated height of the dragged feedback widget
  static const _feedbackHeight = 72.0;

  DropZone _getZoneFromPosition(Offset globalPosition) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return DropZone.none;

    // Calculate center of the dragged item (offset is top-left of feedback)
    final dragCenterGlobal = globalPosition + const Offset(0, _feedbackHeight / 2);
    final localPosition = box.globalToLocal(dragCenterGlobal);
    final height = box.size.height;

    // Top 20% → insert before, Middle 60% → make child, Bottom 20% → insert after
    if (localPosition.dy < height * 0.20) {
      return DropZone.top;
    } else if (localPosition.dy > height * 0.80) {
      return DropZone.bottom;
    } else {
      return DropZone.center;
    }
  }

  bool _canAcceptForZone(DropZone zone, CategoryTreeNode dragged) {
    switch (zone) {
      case DropZone.top:
        return widget.canAcceptBefore(dragged, widget.targetNode);
      case DropZone.center:
        return widget.canAcceptAsChild(dragged, widget.targetNode);
      case DropZone.bottom:
        return widget.canAcceptAfter(dragged, widget.targetNode);
      case DropZone.none:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.highlightColor ?? AppColors.accentPrimary;

    return DragTarget<CategoryTreeNode>(
      onWillAcceptWithDetails: (details) {
        final zone = _getZoneFromPosition(details.offset);
        final canAccept = _canAcceptForZone(zone, details.data);

        if (canAccept && _currentZone != zone) {
          setState(() => _currentZone = zone);
        } else if (!canAccept && _currentZone != DropZone.none) {
          setState(() => _currentZone = DropZone.none);
        }

        return canAccept;
      },
      onAcceptWithDetails: (details) {
        final zone = _currentZone;
        setState(() => _currentZone = DropZone.none);

        switch (zone) {
          case DropZone.top:
            widget.onAcceptBefore(details.data, widget.targetNode);
            break;
          case DropZone.center:
            widget.onAcceptAsChild(details.data, widget.targetNode);
            break;
          case DropZone.bottom:
            widget.onAcceptAfter(details.data, widget.targetNode);
            break;
          case DropZone.none:
            break;
        }
      },
      onLeave: (_) {
        setState(() => _currentZone = DropZone.none);
      },
      onMove: (details) {
        final zone = _getZoneFromPosition(details.offset);
        final canAccept = _canAcceptForZone(zone, details.data);
        final newZone = canAccept ? zone : DropZone.none;

        if (_currentZone != newZone) {
          setState(() => _currentZone = newZone);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isTopZone = _currentZone == DropZone.top;
        final isCenterZone = _currentZone == DropZone.center;
        final isBottomZone = _currentZone == DropZone.bottom;

        return Column(
          key: _key,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top insertion indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: isTopZone ? 4 : 0,
              margin: EdgeInsets.only(bottom: isTopZone ? 4 : 0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isTopZone
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            // The actual item with highlight
            Stack(
              clipBehavior: Clip.none,
              children: [
                widget.child,
                // Overlay highlight for center zone (positioned to match tile's visual bounds)
                if (isCenterZone)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: AppSpacing.sm, // Account for tile's bottom margin
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Bottom insertion indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: isBottomZone ? 4 : 0,
              margin: EdgeInsets.only(
                top: isBottomZone ? 0 : 0,
                bottom: isBottomZone ? 4 : 0,
              ),
              transform: Matrix4.translationValues(0, isBottomZone ? -AppSpacing.sm : 0, 0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isBottomZone
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

