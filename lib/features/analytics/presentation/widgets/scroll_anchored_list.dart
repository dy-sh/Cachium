import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/analytics_filter_provider.dart';

/// A scrollable list that preserves the visible section's screen position
/// when filter changes cause widgets to resize.
///
/// Accepts a list of **section** widgets (no spacers needed — spacing is added
/// automatically). Only real sections get [GlobalKey]s, so the anchor is always
/// a meaningful content widget rather than a spacer.
///
/// After a filter change, the correction runs across several frames to handle
/// widgets that load data asynchronously and settle over multiple layout passes.
class ScrollAnchoredList extends ConsumerStatefulWidget {
  final List<Widget> sections;

  const ScrollAnchoredList({
    super.key,
    required this.sections,
  });

  @override
  ConsumerState<ScrollAnchoredList> createState() =>
      _ScrollAnchoredListState();
}

class _ScrollAnchoredListState extends ConsumerState<ScrollAnchoredList> {
  final _scrollController = ScrollController();
  late List<GlobalKey> _keys;

  /// Number of post-frame correction passes after a filter change.
  static const _correctionFrames = 5;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.sections.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(ScrollAnchoredList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sections.length != _keys.length) {
      final oldKeys = _keys;
      _keys = List.generate(widget.sections.length, (i) {
        return i < oldKeys.length ? oldKeys[i] : GlobalKey();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Find the first section whose bottom edge is below the top of the
  /// scroll viewport — i.e. it's at least partially visible.
  (int, double)? _findVisibleSection() {
    if (!_scrollController.hasClients) return null;

    // Get the top of the scrollable area in global coordinates.
    final scrollContext = _scrollController.position.context.storageContext;
    final scrollBox = scrollContext.findRenderObject() as RenderBox?;
    final viewportTop = scrollBox?.localToGlobal(Offset.zero).dy ?? 0;

    for (int i = 0; i < _keys.length; i++) {
      final ctx = _keys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final screenY = box.localToGlobal(Offset.zero).dy;
      final bottomY = screenY + box.size.height;

      // Section is at least partially visible below the viewport top.
      if (bottomY > viewportTop) {
        return (i, screenY);
      }
    }
    return null;
  }

  void _onFilterChanged() {
    final anchor = _findVisibleSection();
    if (anchor == null) return;
    final (index, screenY) = anchor;

    _scheduleCorrection(index, screenY, _correctionFrames);
  }

  void _scheduleCorrection(int index, double targetScreenY, int remaining) {
    if (remaining <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final ctx = _keys[index].currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;

      final currentScreenY = box.localToGlobal(Offset.zero).dy;
      final delta = currentScreenY - targetScreenY;

      if (delta.abs() > 0.5) {
        final newOffset = (_scrollController.offset + delta).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(newOffset);
      }

      // Schedule another pass — widgets may still be settling.
      _scheduleCorrection(index, targetScreenY, remaining - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analyticsFilterProvider, (_, __) => _onFilterChanged());

    // Build a flat list: section, spacing, section, spacing, …, section.
    final itemCount = widget.sections.length * 2 - 1;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.bottomNavHeight + AppSpacing.lg,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return const SizedBox(height: AppSpacing.lg);
        }
        final sectionIndex = index ~/ 2;
        return KeyedSubtree(
          key: _keys[sectionIndex],
          child: widget.sections[sectionIndex],
        );
      },
    );
  }
}
