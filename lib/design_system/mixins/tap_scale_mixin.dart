import 'package:flutter/material.dart';
import '../../core/constants/app_animations.dart';

/// A mixin that provides tap scale animation functionality.
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with SingleTickerProviderStateMixin, TapScaleMixin {
///
///   @override
///   double get tapScale => AppAnimations.tapScaleDefault;
///
///   @override
///   Widget build(BuildContext context) {
///     return GestureDetector(
///       onTap: widget.onTap,
///       onTapDown: handleTapDown,
///       onTapUp: handleTapUp,
///       onTapCancel: handleTapCancel,
///       child: buildScaleTransition(
///         child: MyContent(),
///       ),
///     );
///   }
/// }
/// ```
mixin TapScaleMixin<T extends StatefulWidget> on SingleTickerProviderStateMixin<T> {
  late AnimationController _tapScaleController;
  late Animation<double> _tapScaleAnimation;

  /// The scale value when pressed. Override to customize.
  double get tapScale => AppAnimations.tapScaleDefault;

  /// Whether the widget is currently enabled for tap interactions.
  /// Override to add custom logic.
  bool get isTapEnabled => true;

  @override
  void initState() {
    super.initState();
    _initTapScaleAnimation();
  }

  void _initTapScaleAnimation() {
    _tapScaleController = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _tapScaleAnimation = Tween<double>(begin: 1.0, end: tapScale).animate(
      CurvedAnimation(parent: _tapScaleController, curve: AppAnimations.defaultCurve),
    );
  }

  @override
  void dispose() {
    _tapScaleController.dispose();
    super.dispose();
  }

  /// Handle tap down event. Call this from GestureDetector.onTapDown.
  void handleTapDown(TapDownDetails details) {
    if (isTapEnabled) {
      _tapScaleController.forward();
    }
  }

  /// Handle tap up event. Call this from GestureDetector.onTapUp.
  void handleTapUp(TapUpDetails details) {
    _tapScaleController.reverse();
  }

  /// Handle tap cancel event. Call this from GestureDetector.onTapCancel.
  void handleTapCancel() {
    _tapScaleController.reverse();
  }

  /// Wraps the child widget with the scale animation.
  Widget buildScaleTransition({required Widget child}) {
    return AnimatedBuilder(
      animation: _tapScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _tapScaleAnimation.value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Access to the animation for custom usage.
  Animation<double> get scaleAnimation => _tapScaleAnimation;

  /// Access to the controller for custom usage.
  AnimationController get scaleController => _tapScaleController;
}
