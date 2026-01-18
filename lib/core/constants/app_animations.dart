import 'package:flutter/animation.dart';

/// Centralized animation constants for consistent behavior across the app.
class AppAnimations {
  AppAnimations._();

  // Animation durations
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration pageTransition = Duration(milliseconds: 400);

  // Tap scale values
  static const double tapScaleDefault = 0.96;
  static const double tapScaleCard = 0.98;
  static const double tapScaleSmall = 0.95;
  static const double tapScaleLarge = 0.9;

  // Common curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutCubic;
}
