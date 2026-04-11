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
/// Sections are lazy-loaded: they render a lightweight placeholder until they
/// come within [_preloadDistance] of the viewport, then inflate the real widget.
/// Once activated, sections stay activated (they are never unloaded).
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

  /// Tracks which sections have been activated (scrolled into view).
  /// Once activated, a section stays activated even if scrolled away.
  late List<bool> _activated;

  /// How far ahead of the viewport to pre-load sections (in pixels).
  static const _preloadDistance = 300.0;

  /// Number of post-frame correction passes after a filter change.
  static const _correctionFrames = 5;

  /// Number of sections to activate immediately without lazy loading.
  /// The first few sections are visible right away, so no point deferring.
  static const _immediateActivateCount = 3;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.sections.length, (_) => GlobalKey());
    _activated = List.generate(widget.sections.length, (i) => i < _immediateActivateCount);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ScrollAnchoredList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sections.length != _keys.length) {
      final oldKeys = _keys;
      final oldActivated = _activated;
      _keys = List.generate(widget.sections.length, (i) {
        return i < oldKeys.length ? oldKeys[i] : GlobalKey();
      });
      _activated = List.generate(widget.sections.length, (i) {
        if (i < _immediateActivateCount) return true;
        return i < oldActivated.length ? oldActivated[i] : false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _activateVisibleSections();
  }

  /// Activate sections that are within the viewport + preload distance.
  void _activateVisibleSections() {
    if (!_scrollController.hasClients) return;

    bool changed = false;
    final viewportTop = _scrollController.offset - _preloadDistance;
    final viewportBottom =
        _scrollController.offset + _scrollController.position.viewportDimension + _preloadDistance;

    for (int i = 0; i < _keys.length; i++) {
      if (_activated[i]) continue;

      final ctx = _keys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      // Get the position relative to the scroll viewport.
      final scrollRenderObject = _scrollController.position.context.storageContext
          .findRenderObject() as RenderBox?;
      if (scrollRenderObject == null) continue;

      final localOffset = box.localToGlobal(Offset.zero,
          ancestor: scrollRenderObject);
      final sectionTop = _scrollController.offset + localOffset.dy;
      final sectionBottom = sectionTop + box.size.height;

      // Section overlaps the extended viewport.
      if (sectionBottom >= viewportTop && sectionTop <= viewportBottom) {
        _activated[i] = true;
        changed = true;
      }
    }

    if (changed) {
      setState(() {});
    }
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
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.bottomNavHeight + AppSpacing.lg,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return const SizedBox(height: AppSpacing.lg);
        }
        final sectionIndex = index ~/ 2;
        final child = _activated[sectionIndex]
            ? widget.sections[sectionIndex]
            : const _LazyPlaceholder();
        return KeyedSubtree(
          key: _keys[sectionIndex],
          child: child,
        );
      },
    );
  }
}

/// Lightweight placeholder shown for sections that haven't been scrolled into
/// view yet. Provides a minimum height so the scroll extent is reasonable.
class _LazyPlaceholder extends StatelessWidget {
  const _LazyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 200);
  }
}
