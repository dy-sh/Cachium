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

class CategoryItemDropTarget extends StatefulWidget {
  final Widget child;
  final CategoryTreeNode targetNode;
  final bool Function(CategoryTreeNode dragged, CategoryTreeNode target, int depth) canAccept;
  final void Function(CategoryTreeNode dragged, CategoryTreeNode target, int depth) onAccept;
  final void Function(CategoryTreeNode targetNode, int depth)? onHoverChanged;
  final Color? highlightColor;
  final bool suppressPlaceholder; // Don't show placeholder (used when this is the dragged item)

  const CategoryItemDropTarget({
    super.key,
    required this.child,
    required this.targetNode,
    required this.canAccept,
    required this.onAccept,
    this.onHoverChanged,
    this.highlightColor,
    this.suppressPlaceholder = false,
  });

  @override
  State<CategoryItemDropTarget> createState() => _CategoryItemDropTargetState();
}

class _CategoryItemDropTargetState extends State<CategoryItemDropTarget> {
  bool _isHovering = false;
  int _currentDepth = 0;
  final GlobalKey _key = GlobalKey();

  // Estimated height of the dragged feedback widget
  static const _feedbackHeight = 72.0;
  static const _depthIndentation = 24.0;

  int _getDepthFromPosition(Offset globalPosition, CategoryTreeNode draggedNode) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return widget.targetNode.depth;

    // Calculate depth from horizontal position
    // The feedback's visual content is offset by the dragged node's original depth margin
    final dragLeftLocal = box.globalToLocal(globalPosition);
    final visualLeftLocal = dragLeftLocal.dx + (draggedNode.depth * _depthIndentation);

    // Round to nearest depth level for snapping behavior
    // Min depth is 0 (root), max depth is target.depth + 1 (as child of target)
    int rawDepth = (visualLeftLocal / _depthIndentation).round();
    return rawDepth.clamp(0, widget.targetNode.depth + 1);
  }

  void _notifyHoverChanged(int depth) {
    widget.onHoverChanged?.call(widget.targetNode, depth);
  }

  void _notifyHoverCleared() {
    // Pass a negative depth to indicate no hover
    widget.onHoverChanged?.call(widget.targetNode, -1);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.highlightColor ?? AppColors.accentPrimary;

    return DragTarget<CategoryTreeNode>(
      onWillAcceptWithDetails: (details) {
        final depth = _getDepthFromPosition(details.offset, details.data);
        final canAccept = widget.canAccept(details.data, widget.targetNode, depth);

        if (canAccept && (!_isHovering || _currentDepth != depth)) {
          setState(() {
            _isHovering = true;
            _currentDepth = depth;
          });
          _notifyHoverChanged(depth);
        } else if (!canAccept && _isHovering) {
          setState(() => _isHovering = false);
          _notifyHoverCleared();
        }

        return canAccept;
      },
      onAcceptWithDetails: (details) {
        final depth = _currentDepth;
        setState(() => _isHovering = false);
        _notifyHoverCleared();
        widget.onAccept(details.data, widget.targetNode, depth);
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
        _notifyHoverCleared();
      },
      onMove: (details) {
        final depth = _getDepthFromPosition(details.offset, details.data);
        final canAccept = widget.canAccept(details.data, widget.targetNode, depth);

        if (canAccept && (!_isHovering || _currentDepth != depth)) {
          setState(() {
            _isHovering = true;
            _currentDepth = depth;
          });
          _notifyHoverChanged(depth);
        } else if (!canAccept && _isHovering) {
          setState(() => _isHovering = false);
          _notifyHoverCleared();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final previewIndentation = _currentDepth * _depthIndentation;

        return Column(
          key: _key,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The actual item
            widget.child,
            // Preview placeholder showing where item will be inserted (AFTER the target)
            // Don't show if this is the dragged item (childWhenDragging handles it)
            if (_isHovering && !widget.suppressPlaceholder)
              Transform.translate(
                offset: Offset(0, -AppSpacing.sm),
                child: Container(
                  height: _feedbackHeight,
                  margin: EdgeInsets.only(
                    left: previewIndentation,
                    bottom: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

