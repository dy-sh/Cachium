import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../data/models/account_flow.dart';

class FlowDiagram extends StatelessWidget {
  final AccountFlowData flowData;

  const FlowDiagram({super.key, required this.flowData});

  @override
  Widget build(BuildContext context) {
    final nodeCount = math.max(flowData.incomeNodes.length, flowData.expenseNodes.length);
    final height = math.max(200.0, nodeCount * 40.0 + 20.0);

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _FlowPainter(flowData: flowData),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildLabels(flowData.incomeNodes, CrossAxisAlignment.start, height),
            ),
            const Expanded(flex: 4, child: SizedBox()),
            Expanded(
              flex: 3,
              child: _buildLabels(flowData.expenseNodes, CrossAxisAlignment.end, height),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabels(List<FlowNode> nodes, CrossAxisAlignment alignment, double totalHeight) {
    if (nodes.isEmpty) return const SizedBox();

    final heights = _computeNodeHeights(nodes, totalHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: List.generate(nodes.length, (i) {
        final node = nodes[i];
        return SizedBox(
          height: heights[i] + _gapSize,
          child: Align(
            alignment: alignment == CrossAxisAlignment.start
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Text(
              '${node.label} (${node.percentage.toStringAsFixed(0)}%)',
              style: AppTypography.labelSmall.copyWith(
                color: node.color,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }),
    );
  }
}

const double _gapSize = 4.0;
const double _topPadding = 10.0;

/// Computes node heights that are proportional to percentage but guaranteed
/// to fit within [totalHeight] (minus padding and gaps).
List<double> _computeNodeHeights(List<FlowNode> nodes, double totalHeight) {
  if (nodes.isEmpty) return [];
  final usable = totalHeight - _topPadding - (nodes.length * _gapSize);
  final minH = 14.0;
  final totalPercent = nodes.fold<double>(0, (s, n) => s + n.percentage);

  // First pass: proportional
  final heights = nodes.map((n) {
    final proportion = totalPercent > 0 ? n.percentage / totalPercent : 1.0 / nodes.length;
    return math.max(minH, proportion * usable);
  }).toList();

  // Scale down if total exceeds usable
  final sum = heights.fold<double>(0, (s, h) => s + h);
  if (sum > usable && sum > 0) {
    final scale = usable / sum;
    for (var i = 0; i < heights.length; i++) {
      heights[i] = math.max(minH, heights[i] * scale);
    }
  }

  return heights;
}

class _FlowPainter extends CustomPainter {
  final AccountFlowData flowData;

  _FlowPainter({required this.flowData});

  @override
  void paint(Canvas canvas, Size size) {
    if (flowData.incomeNodes.isEmpty && flowData.expenseNodes.isEmpty) return;

    final leftX = size.width * 0.3;
    final rightX = size.width * 0.7;
    final centerX = size.width * 0.5;

    _drawNodes(canvas, size, flowData.incomeNodes, leftX, isLeft: true);
    _drawNodes(canvas, size, flowData.expenseNodes, rightX, isLeft: false);
    _drawCurves(canvas, size, leftX, rightX, centerX);
  }

  void _drawNodes(Canvas canvas, Size size, List<FlowNode> nodes, double x, {required bool isLeft}) {
    final heights = _computeNodeHeights(nodes, size.height);
    double y = _topPadding;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final h = heights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(isLeft ? x - 4 : x, y, 4, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, Paint()..color = node.color);
      y += h + _gapSize;
    }
  }

  void _drawCurves(Canvas canvas, Size size, double leftX, double rightX, double centerX) {
    final leftHeights = _computeNodeHeights(flowData.incomeNodes, size.height);
    final rightHeights = _computeNodeHeights(flowData.expenseNodes, size.height);

    double leftY = _topPadding;
    for (var li = 0; li < flowData.incomeNodes.length; li++) {
      final incomeNode = flowData.incomeNodes[li];
      final lh = leftHeights[li];
      final startY = leftY + lh / 2;

      double rightY = _topPadding;
      for (var ri = 0; ri < flowData.expenseNodes.length; ri++) {
        final expenseNode = flowData.expenseNodes[ri];
        final rh = rightHeights[ri];
        final endY = rightY + rh / 2;

        final flowRatio = (incomeNode.percentage * expenseNode.percentage) / 10000;
        final strokeWidth = math.max(0.5, flowRatio * (size.height - 20) * 0.3);

        final path = Path()
          ..moveTo(leftX, startY)
          ..cubicTo(centerX, startY, centerX, endY, rightX, endY);

        final paint = Paint()
          ..color = incomeNode.color.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

        canvas.drawPath(path, paint);
        rightY += rh + _gapSize;
      }
      leftY += lh + _gapSize;
    }
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) => oldDelegate.flowData != flowData;
}
