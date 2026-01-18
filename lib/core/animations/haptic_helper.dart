import 'package:flutter/services.dart';

/// Haptic feedback helper for consistent tactile interactions
class HapticHelper {
  HapticHelper._();

  /// Light tap feedback for buttons and simple interactions
  /// Use for: Regular buttons, tabs, simple selections
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium tap feedback for selections and form interactions
  /// Use for: Dropdowns, checkboxes, radio buttons, category/account selections
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap feedback for confirmations and important actions
  /// Use for: Save button, delete confirmations, important state changes
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback for changing values
  /// Use for: Sliders, pickers, incrementing/decrementing values
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate for errors and warnings
  /// Use for: Form validation errors, delete warnings
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}
