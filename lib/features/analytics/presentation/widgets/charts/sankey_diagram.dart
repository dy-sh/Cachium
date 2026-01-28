import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../data/models/sankey_flow.dart';

class SankeyDiagram extends StatefulWidget {
  final SankeyData data;
  final String currencySymbol;

  const SankeyDiagram({
    super.key,
    required this.data,
    required this.currencySymbol,
  });

  @override
  State<SankeyDiagram> createState() => _SankeyDiagramState();
}

class _SankeyDiagramState extends State<SankeyDiagram> {
  String? _selectedNodeId;
  Offset? _tooltipPosition;
  SankeyNode? _selectedNode;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return _buildEmptyState();

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final painter = _SankeyPainter(
                  data: widget.data,
                  currencySymbol: widget.currencySymbol,
                  selectedNodeId: _selectedNodeId,
                );
                return Stack(
                  children: [
                    GestureDetector(
                      onTapDown: (details) => _handleTap(details, constraints.biggest, painter),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: painter,
                      ),
                    ),
                    if (_selectedNode != null && _tooltipPosition != null)
                      Positioned(
                        left: _tooltipPosition!.dx.clamp(0, constraints.maxWidth - 120),
                        top: (_tooltipPosition!.dy - 40).clamp(0, constraints.maxHeight - 36),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _selectedNode!.color),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${_selectedNode!.label}: ${_formatAmount(_selectedNode!.amount)}',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapDownDetails details, Size size, _SankeyPainter painter) {
    final allPositions = painter.computeAllPositions(size);
    final tapPoint = details.localPosition;

    for (final entry in allPositions.entries) {
      // Expand hit area slightly for easier tapping
      final expandedRect = entry.value.inflate(4);
      if (expandedRect.contains(tapPoint)) {
        setState(() {
          if (_selectedNodeId == entry.key) {
            _selectedNodeId = null;
            _selectedNode = null;
            _tooltipPosition = null;
          } else {
            _selectedNodeId = entry.key;
            _selectedNode = _findNode(entry.key);
            _tooltipPosition = tapPoint;
          }
        });
        return;
      }
    }

    // Tapped empty space - deselect
    setState(() {
      _selectedNodeId = null;
      _selectedNode = null;
      _tooltipPosition = null;
    });
  }

  SankeyNode? _findNode(String id) {
    for (final n in widget.data.sourceNodes) {
      if (n.id == id) return n;
    }
    for (final n in widget.data.targetNodes) {
      if (n.id == id) return n;
    }
    if (widget.data.middleNodes != null) {
      for (final n in widget.data.middleNodes!) {
        if (n.id == id) return n;
      }
    }
    return null;
  }

  String _formatAmount(double value) {
    if (value.abs() >= 1000000) return '${widget.currencySymbol}${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${widget.currencySymbol}${(value / 1000).toStringAsFixed(1)}K';
    return '${widget.currencySymbol}${value.toStringAsFixed(0)}';
  }

  double _calculateHeight() {
    final nodeCount = (widget.data.sourceNodes.length > widget.data.targetNodes.length
        ? widget.data.sourceNodes.length
        : widget.data.targetNodes.length);
    final middleCount = widget.data.middleNodes?.length ?? 0;
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
  final String? selectedNodeId;

  _SankeyPainter({
    required this.data,
    required this.currencySymbol,
    this.selectedNodeId,
  });

  Map<String, Rect> computeAllPositions(Size size) {
    final hasMiddle = data.middleNodes != null && data.middleNodes!.isNotEmpty;
    final double leftX = 0;
    final double rightX = size.width - 80;
    final double midX = hasMiddle ? size.width / 2 - 40 : 0;

    final sourcePositions = _layoutNodes(data.sourceNodes, size.height, leftX);
    final targetPositions = _layoutNodes(data.targetNodes, size.height, rightX);
    Map<String, Rect> middlePositions = {};
    if (hasMiddle) {
      middlePositions = _layoutNodes(data.middleNodes!, size.height, midX);
    }
    return {...sourcePositions, ...targetPositions, ...middlePositions};
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hasMiddle = data.middleNodes != null && data.middleNodes!.isNotEmpty;

    final double leftX = 0;
    final double rightX = size.width - 80;
    final double midX = hasMiddle ? size.width / 2 - 40 : 0;

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

      final isConnected = selectedNodeId != null &&
          (link.sourceId == selectedNodeId || link.targetId == selectedNodeId);
      final dimmed = selectedNodeId != null && !isConnected;

      final paint = Paint()
        ..color = dimmed ? link.color.withValues(alpha: 0.15) : link.color
        ..style = PaintingStyle.fill;

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

      final dimmed = selectedNodeId != null && selectedNodeId != node.id;
      final paint = Paint()
        ..color = dimmed ? node.color.withValues(alpha: 0.4) : node.color
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

      final dimmed = selectedNodeId != null && selectedNodeId != node.id;
      final textSpan = TextSpan(
        text: node.label,
        style: TextStyle(
          color: dimmed ? AppColors.textSecondary.withValues(alpha: 0.4) : AppColors.textSecondary,
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
    return oldDelegate.data != data || oldDelegate.selectedNodeId != selectedNodeId;
  }
}
