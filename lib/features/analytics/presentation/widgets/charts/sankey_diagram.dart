import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../data/models/sankey_flow.dart';

class SankeyDiagram extends StatelessWidget {
  final SankeyData data;
  final String currencySymbol;

  const SankeyDiagram({
    super.key,
    required this.data,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _buildEmptyState();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Money Flow', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: _calculateHeight(),
            child: CustomPaint(
              size: Size.infinite,
              painter: _SankeyPainter(data: data, currencySymbol: currencySymbol),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateHeight() {
    final nodeCount = (data.sourceNodes.length > data.targetNodes.length
        ? data.sourceNodes.length
        : data.targetNodes.length);
    final middleCount = data.middleNodes?.length ?? 0;
    final maxCount = nodeCount > middleCount ? nodeCount : middleCount;
    return (maxCount * 36.0 + 20).clamp(120.0, 400.0);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Money Flow', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xxl),
          Center(child: Text('No data available', style: AppTypography.bodySmall)),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _SankeyPainter extends CustomPainter {
  final SankeyData data;
  final String currencySymbol;

  _SankeyPainter({required this.data, required this.currencySymbol});

  @override
  void paint(Canvas canvas, Size size) {
    final hasMiddle = data.middleNodes != null && data.middleNodes!.isNotEmpty;

    // Column positions
    final double leftX = 0;
    final double rightX = size.width - 80;
    final double midX = hasMiddle ? size.width / 2 - 40 : 0;

    // Position source nodes
    final sourcePositions = _layoutNodes(data.sourceNodes, size.height, leftX);
    final targetPositions = _layoutNodes(data.targetNodes, size.height, rightX);
    Map<String, Rect> middlePositions = {};
    if (hasMiddle) {
      middlePositions = _layoutNodes(data.middleNodes!, size.height, midX);
    }

    final allPositions = {...sourcePositions, ...targetPositions, ...middlePositions};

    // Draw links first (behind nodes)
    for (final link in data.links) {
      final srcRect = allPositions[link.sourceId];
      final tgtRect = allPositions[link.targetId];
      if (srcRect == null || tgtRect == null) continue;

      final paint = Paint()
        ..color = link.color
        ..style = PaintingStyle.fill;

      // Compute proportional thickness
      final srcNode = _findNode(link.sourceId);
      final tgtNode = _findNode(link.targetId);
      if (srcNode == null || tgtNode == null) continue;

      final srcTotal = srcNode.amount > 0 ? srcNode.amount : 1;
      final thickness = (link.amount / srcTotal * srcRect.height).clamp(1.0, srcRect.height);

      final startY = srcRect.center.dy;
      final endY = tgtRect.center.dy;

      final path = Path()
        ..moveTo(srcRect.right, startY - thickness / 2)
        ..cubicTo(
          srcRect.right + (tgtRect.left - srcRect.right) * 0.4,
          startY - thickness / 2,
          tgtRect.left - (tgtRect.left - srcRect.right) * 0.4,
          endY - thickness / 2,
          tgtRect.left,
          endY - thickness / 2,
        )
        ..lineTo(tgtRect.left, endY + thickness / 2)
        ..cubicTo(
          tgtRect.left - (tgtRect.left - srcRect.right) * 0.4,
          endY + thickness / 2,
          srcRect.right + (tgtRect.left - srcRect.right) * 0.4,
          startY + thickness / 2,
          srcRect.right,
          startY + thickness / 2,
        )
        ..close();

      canvas.drawPath(path, paint);
    }

    // Draw nodes
    _drawNodes(canvas, data.sourceNodes, sourcePositions);
    _drawNodes(canvas, data.targetNodes, targetPositions);
    if (hasMiddle) {
      _drawNodes(canvas, data.middleNodes!, middlePositions);
    }

    // Draw labels
    _drawLabels(canvas, data.sourceNodes, sourcePositions, true);
    _drawLabels(canvas, data.targetNodes, targetPositions, false);
    if (hasMiddle) {
      _drawLabels(canvas, data.middleNodes!, middlePositions, true);
    }
  }

  SankeyNode? _findNode(String id) {
    for (final n in data.sourceNodes) {
      if (n.id == id) return n;
    }
    for (final n in data.targetNodes) {
      if (n.id == id) return n;
    }
    if (data.middleNodes != null) {
      for (final n in data.middleNodes!) {
        if (n.id == id) return n;
      }
    }
    return null;
  }

  Map<String, Rect> _layoutNodes(List<SankeyNode> nodes, double height, double x) {
    if (nodes.isEmpty) return {};
    const nodeWidth = 8.0;
    const spacing = 4.0;

    final totalAmount = nodes.fold(0.0, (s, n) => s + n.amount);
    final availableHeight = height - (nodes.length - 1) * spacing;

    final positions = <String, Rect>{};
    double y = 0;

    for (final node in nodes) {
      final nodeHeight = totalAmount > 0
          ? (node.amount / totalAmount * availableHeight).clamp(8.0, availableHeight)
          : availableHeight / nodes.length;

      positions[node.id] = Rect.fromLTWH(x, y, nodeWidth, nodeHeight);
      y += nodeHeight + spacing;
    }

    return positions;
  }

  void _drawNodes(Canvas canvas, List<SankeyNode> nodes, Map<String, Rect> positions) {
    for (final node in nodes) {
      final rect = positions[node.id];
      if (rect == null) continue;

      final paint = Paint()
        ..color = node.color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
    }
  }

  void _drawLabels(Canvas canvas, List<SankeyNode> nodes, Map<String, Rect> positions, bool alignLeft) {
    for (final node in nodes) {
      final rect = positions[node.id];
      if (rect == null) continue;

      final textSpan = TextSpan(
        text: node.label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 70);

      final dx = alignLeft ? rect.right + 4 : rect.left - textPainter.width - 4;
      final dy = rect.center.dy - textPainter.height / 2;
      textPainter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _SankeyPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
