import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../exceptions/app_exception.dart';

/// Mixin that adds optimistic update helpers to `AsyncNotifier<List<T>>`.
///
/// Provides [runOptimistic] which handles the common pattern of:
/// 1. Saving previous state
/// 2. Optimistically updating local state
/// 3. Executing the async operation
/// 4. Rolling back on error and re-throwing
///
/// Mutations are serialized via an internal future chain to prevent
/// concurrent mutations from corrupting each other's rollback state.
mixin OptimisticAsyncNotifier<T> on AsyncNotifier<List<T>> {
  Future<void>? _pending;

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
    // Chain onto any pending mutation to serialize access
    final completer = Completer<R>();
    final previous = _pending;
    _pending = completer.future.then((_) {}, onError: (_) {});

    if (previous != null) await previous;

    final previousState = state;
    try {
      state = state.whenData(update);
      final result = await action();
      completer.complete(result);
      return result;
    } catch (e, st) {
      state = previousState;
      completer.completeError(e, st);
      Error.throwWithStackTrace(
        e is AppException ? e : onError(e),
        st,
      );
    }
  }
}
