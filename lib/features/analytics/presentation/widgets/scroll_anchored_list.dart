import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/analytics_filter_provider.dart';

/// A scrollable list that preserves the visible section's screen position
/// when filter changes cause widgets to resize.
///
/// Each child is assigned a stable [GlobalKey]. When [analyticsFilterProvider]
/// changes, the widget records which section is currently visible and where it
/// sits on screen, then after the rebuild + layout pass it adjusts the scroll
/// offset so that same section stays at the same screen position.
class ScrollAnchoredList extends ConsumerStatefulWidget {
  final List<Widget> children;

  const ScrollAnchoredList({
    super.key,
    required this.children,
  });

  @override
  ConsumerState<ScrollAnchoredList> createState() =>
      _ScrollAnchoredListState();
}

class _ScrollAnchoredListState extends ConsumerState<ScrollAnchoredList> {
  final _scrollController = ScrollController();
  late List<GlobalKey> _keys;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.children.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(ScrollAnchoredList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != _keys.length) {
      _keys = List.generate(widget.children.length, (i) {
        return i < _keys.length ? _keys[i] : GlobalKey();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Find the first section whose bottom edge is below the top of the
  /// viewport — i.e. it's at least partially visible.
  (int, double)? _findVisibleSection() {
    if (!_scrollController.hasClients) return null;

    for (int i = 0; i < _keys.length; i++) {
      final ctx = _keys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final screenY = box.localToGlobal(Offset.zero).dy;
      final bottomY = screenY + box.size.height;

      if (bottomY > 0) {
        return (i, screenY);
      }
    }
    return null;
  }

  void _onFilterChanged() {
    final anchor = _findVisibleSection();
    if (anchor == null) return;
    final (index, screenY) = anchor;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final ctx = _keys[index].currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;

      final newScreenY = box.localToGlobal(Offset.zero).dy;
      final delta = newScreenY - screenY;

      if (delta.abs() > 1) {
        final newOffset = (_scrollController.offset + delta).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analyticsFilterProvider, (_, __) => _onFilterChanged());

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.bottomNavHeight + AppSpacing.lg,
      ),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return KeyedSubtree(
          key: _keys[index],
          child: widget.children[index],
        );
      },
    );
  }
}
