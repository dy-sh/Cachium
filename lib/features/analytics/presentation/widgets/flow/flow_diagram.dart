import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../data/models/account_flow.dart';

class FlowDiagram extends StatefulWidget {
  final AccountFlowData flowData;
  final String currencySymbol;

  const FlowDiagram({
    super.key,
    required this.flowData,
    this.currencySymbol = '\$',
  });

  @override
  State<FlowDiagram> createState() => _FlowDiagramState();
}

class _FlowDiagramState extends State<FlowDiagram>
    with SingleTickerProviderStateMixin {
  int? _selectedNodeIndex; // null=none, 0..incomeLen-1=income, incomeLen..=expense
  bool _isIncomeSelected = false;
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _onNodeTap(int index, bool isIncome) {
    setState(() {
      if (_selectedNodeIndex == index && _isIncomeSelected == isIncome) {
        _selectedNodeIndex = null;
      } else {
        _selectedNodeIndex = index;
        _isIncomeSelected = isIncome;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nodeCount = math.max(
      widget.flowData.incomeNodes.length,
      widget.flowData.expenseNodes.length,
    );
    final height = math.max(200.0, nodeCount * 40.0 + 20.0);

    final selectedNode = _selectedNodeIndex != null
        ? (_isIncomeSelected
            ? widget.flowData.incomeNodes[_selectedNodeIndex!]
            : widget.flowData.expenseNodes[_selectedNodeIndex!])
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: AnimatedBuilder(
            animation: _entryAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _FlowPainter(
                  flowData: widget.flowData,
                  selectedIndex: _selectedNodeIndex,
                  isIncomeSelected: _isIncomeSelected,
                  entryProgress: _entryAnimation.value,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildLabels(
                        widget.flowData.incomeNodes,
                        CrossAxisAlignment.start,
                        height,
                        isIncome: true,
                      ),
                    ),
                    const Expanded(flex: 4, child: SizedBox()),
                    Expanded(
                      flex: 3,
                      child: _buildLabels(
                        widget.flowData.expenseNodes,
                        CrossAxisAlignment.end,
                        height,
                        isIncome: false,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Tooltip for selected node
        if (selectedNode != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: selectedNode.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  selectedNode.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.currencySymbol}${selectedNode.amount.toStringAsFixed(0)}',
                  style: AppTypography.moneyTiny.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${selectedNode.percentage.toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabels(
    List<FlowNode> nodes,
    CrossAxisAlignment alignment,
    double totalHeight, {
    required bool isIncome,
  }) {
    if (nodes.isEmpty) return const SizedBox();

    final heights = _computeNodeHeights(nodes, totalHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: List.generate(nodes.length, (i) {
        final node = nodes[i];
        final isSelected = _selectedNodeIndex == i && _isIncomeSelected == isIncome;
        return GestureDetector(
          onTap: () => _onNodeTap(i, isIncome),
          child: SizedBox(
            height: heights[i] + _gapSize,
            child: Align(
              alignment: alignment == CrossAxisAlignment.start
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Text(
                '${node.label} (${node.percentage.toStringAsFixed(0)}%)',
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? node.color : node.color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }),
    );
  }
}

const double _gapSize = 4.0;
const double _topPadding = 10.0;

List<double> _computeNodeHeights(List<FlowNode> nodes, double totalHeight) {
  if (nodes.isEmpty) return [];
  final usable = totalHeight - _topPadding - (nodes.length * _gapSize);
  final minH = 14.0;
  final totalPercent = nodes.fold<double>(0, (s, n) => s + n.percentage);

  final heights = nodes.map((n) {
    final proportion = totalPercent > 0 ? n.percentage / totalPercent : 1.0 / nodes.length;
    return math.max(minH, proportion * usable);
  }).toList();

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
  final int? selectedIndex;
  final bool isIncomeSelected;
  final double entryProgress;

  _FlowPainter({
    required this.flowData,
    this.selectedIndex,
    this.isIncomeSelected = false,
    this.entryProgress = 1.0,
  });

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

        // Determine opacity based on selection
        double opacity;
        if (selectedIndex == null) {
          opacity = 0.15;
        } else if (isIncomeSelected && selectedIndex == li) {
          opacity = 0.4;
        } else if (!isIncomeSelected && selectedIndex == ri) {
          opacity = 0.4;
        } else {
          opacity = 0.05;
        }

        // Apply entry animation
        opacity *= entryProgress;

        final path = Path()
          ..moveTo(leftX, startY)
          ..cubicTo(centerX, startY, centerX, endY, rightX, endY);

        final paint = Paint()
          ..color = incomeNode.color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

        canvas.drawPath(path, paint);
        rightY += rh + _gapSize;
      }
      leftY += lh + _gapSize;
    }
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) =>
      oldDelegate.flowData != flowData ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.isIncomeSelected != isIncomeSelected ||
      oldDelegate.entryProgress != entryProgress;
}
