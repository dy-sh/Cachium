import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/category_breakdown_provider.dart';
import '../../providers/chart_highlight_provider.dart';
import '../../../data/models/category_breakdown.dart';

class TreemapChart extends ConsumerStatefulWidget {
  const TreemapChart({super.key});

  @override
  ConsumerState<TreemapChart> createState() => _TreemapChartState();
}

class _TreemapChartState extends ConsumerState<TreemapChart> {
  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    final breakdowns = ref.watch(categoryBreakdownProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final highlightedCategory = ref.watch(chartHighlightProvider);

    if (breakdowns.isEmpty) return const SizedBox.shrink();

    // Take top 10
    final data = breakdowns.take(10).toList();

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
          Text('Category Treemap', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rects = _squarify(data, constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: (details) {
                    for (int i = 0; i < rects.length; i++) {
                      if (rects[i].contains(details.localPosition)) {
                        setState(() => _tappedIndex = _tappedIndex == i ? null : i);
                        final catId = data[i].categoryId;
                        ref.read(chartHighlightProvider.notifier).state =
                            highlightedCategory == catId ? null : catId;
                        break;
                      }
                    }
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _TreemapPainter(
                      data: data,
                      rects: rects,
                      currencySymbol: currencySymbol,
                      tappedIndex: _tappedIndex,
                      highlightedCategoryId: highlightedCategory,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Rect> _squarify(List<CategoryBreakdown> data, double width, double height) {
    if (data.isEmpty) return [];

    final total = data.fold(0.0, (s, d) => s + d.amount);
    if (total == 0) return List.filled(data.length, Rect.zero);

    final areas = data.map((d) => d.amount / total * width * height).toList();
    final rects = List<Rect>.filled(data.length, Rect.zero);

    _layout(areas, rects, 0, data.length, 0, 0, width, height);
    return rects;
  }

  void _layout(List<double> areas, List<Rect> rects, int start, int end,
      double x, double y, double w, double h) {
    if (start >= end) return;
    if (end - start == 1) {
      rects[start] = Rect.fromLTWH(x, y, w, h);
      return;
    }

    final total = areas.sublist(start, end).fold(0.0, (s, a) => s + a);
    double half = 0;
    int mid = start;

    for (int i = start; i < end; i++) {
      if (half + areas[i] > total / 2 && i > start) break;
      half += areas[i];
      mid = i + 1;
    }

    final ratio = total > 0 ? half / total : 0.5;

    if (w >= h) {
      _layout(areas, rects, start, mid, x, y, w * ratio, h);
      _layout(areas, rects, mid, end, x + w * ratio, y, w * (1 - ratio), h);
    } else {
      _layout(areas, rects, start, mid, x, y, w, h * ratio);
      _layout(areas, rects, mid, end, x, y + h * ratio, w, h * (1 - ratio));
    }
  }
}

class _TreemapPainter extends CustomPainter {
  final List<CategoryBreakdown> data;
  final List<Rect> rects;
  final String currencySymbol;
  final int? tappedIndex;
  final String? highlightedCategoryId;

  _TreemapPainter({
    required this.data,
    required this.rects,
    required this.currencySymbol,
    this.tappedIndex,
    this.highlightedCategoryId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < data.length && i < rects.length; i++) {
      final rect = rects[i].deflate(1.5);
      if (rect.width < 2 || rect.height < 2) continue;

      final d = data[i];
      final isHighlighted = highlightedCategoryId == null || highlightedCategoryId == d.categoryId;
      final isTapped = tappedIndex == i;

      final alpha = isHighlighted ? (isTapped ? 1.0 : 0.7) : 0.2;
      final paint = Paint()
        ..color = d.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

      // Border
      final borderPaint = Paint()
        ..color = d.color.withValues(alpha: isHighlighted ? 0.5 : 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isTapped ? 2 : 1;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

      // Text (only if rect is big enough)
      if (rect.width > 40 && rect.height > 30) {
        final nameSpan = TextSpan(
          text: d.name,
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: isHighlighted ? 1.0 : 0.3),
            fontSize: rect.width > 80 ? 11 : 9,
            fontWeight: FontWeight.w600,
          ),
        );
        final namePainter = TextPainter(
          text: nameSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        )..layout(maxWidth: rect.width - 8);
        namePainter.paint(canvas, Offset(rect.left + 4, rect.top + 4));

        if (rect.height > 45) {
          final amountSpan = TextSpan(
            text: '$currencySymbol${_formatCompact(d.amount)}',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: isHighlighted ? 1.0 : 0.3),
              fontSize: 9,
            ),
          );
          final amountPainter = TextPainter(
            text: amountSpan,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: rect.width - 8);
          amountPainter.paint(canvas, Offset(rect.left + 4, rect.top + 18));
        }
      }
    }
  }

  String _formatCompact(double value) {
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.tappedIndex != tappedIndex ||
        oldDelegate.highlightedCategoryId != highlightedCategoryId;
  }
}
