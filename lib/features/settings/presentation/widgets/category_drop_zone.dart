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
                ? AppColors.accentPrimary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovering
                  ? AppColors.accentPrimary
                  : AppColors.border.withOpacity(0.5),
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
  final bool Function(CategoryTreeNode dragged, CategoryTreeNode target) canAccept;
  final void Function(CategoryTreeNode dragged, CategoryTreeNode target) onAccept;

  const CategoryItemDropTarget({
    super.key,
    required this.child,
    required this.targetNode,
    required this.canAccept,
    required this.onAccept,
  });

  @override
  State<CategoryItemDropTarget> createState() => _CategoryItemDropTargetState();
}

class _CategoryItemDropTargetState extends State<CategoryItemDropTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<CategoryTreeNode>(
      onWillAcceptWithDetails: (details) {
        final canAccept = widget.canAccept(details.data, widget.targetNode);
        if (canAccept && !_isHovering) {
          setState(() => _isHovering = true);
        }
        return canAccept;
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onAccept(details.data, widget.targetNode);
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      builder: (context, candidateData, rejectedData) {
        if (_isHovering) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: widget.child,
          );
        }
        return widget.child;
      },
    );
  }
}
