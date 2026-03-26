import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../exceptions/app_exception.dart';

/// Mixin that adds optimistic update helpers to `AsyncNotifier<List<T>>`.
///
/// Provides [runOptimistic] which handles the common pattern of:
/// 1. Saving previous state
/// 2. Optimistically updating local state
/// 3. Executing the async operation
/// 4. Rolling back on error and re-throwing
mixin OptimisticAsyncNotifier<T> on AsyncNotifier<List<T>> {
  /// Execute an operation with optimistic state update and automatic rollback.
  ///
  /// [update] transforms the current list for optimistic UI.
  /// [action] performs the actual async work (e.g., repo call).
  /// [onError] wraps non-AppException errors before re-throwing.
  Future<R> runOptimistic<R>({
    required List<T> Function(List<T> items) update,
    required Future<R> Function() action,
    required AppException Function(Object cause) onError,
  }) async {
    final previousState = state;
    try {
      state = state.whenData(update);
      return await action();
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : onError(e),
        st,
      );
    }
  }
}
