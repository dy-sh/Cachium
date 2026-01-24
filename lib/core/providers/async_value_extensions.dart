import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extensions for AsyncValue to reduce boilerplate.
extension AsyncValueListExtension<T> on AsyncValue<List<T>> {
  /// Returns the value if available, or an empty list if null.
  ///
  /// This is a convenience method to replace the common pattern:
  /// ```dart
  /// final items = asyncValue.valueOrNull ?? [];
  /// ```
  List<T> get valueOrEmpty => valueOrNull ?? [];
}
