import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_placeholder.dart';
import 'loading_indicator.dart';

/// A reusable widget that handles [AsyncValue] states (loading, error, data)
/// with consistent UI patterns across the app.
///
/// Provides default loading (pulsing dots) and error (red text) widgets,
/// with optional overrides and an empty-state builder.
///
/// Usage:
/// ```dart
/// AsyncValueBuilder<List<Transaction>>(
///   value: ref.watch(transactionsProvider),
///   data: (transactions) => TransactionList(transactions: transactions),
///   empty: (data) => data.isEmpty,
///   emptyBuilder: () => EmptyState.centered(message: 'No transactions'),
/// )
/// ```
class AsyncValueBuilder<T> extends StatelessWidget {
  /// The async value to render.
  final AsyncValue<T> value;

  /// Builder for the data state.
  final Widget Function(T data) data;

  /// Optional loading widget override. Defaults to [LoadingIndicator].
  final Widget? loading;

  /// Optional error widget override. Defaults to [ErrorPlaceholder].
  final Widget Function(Object error, StackTrace stack)? error;

  /// Optional retry callback. When provided and no custom [error] builder
  /// is set, the default [ErrorPlaceholder] will show a "Try again" button.
  final VoidCallback? onRetry;

  /// Optional predicate to determine if the data is "empty".
  /// When true and [emptyBuilder] is provided, shows the empty state instead.
  final bool Function(T data)? empty;

  /// Widget to show when [empty] returns true.
  final Widget Function()? emptyBuilder;

  /// If true, shows previous data while refreshing (default: true).
  final bool skipLoadingOnRefresh;

  const AsyncValueBuilder({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
    this.empty,
    this.emptyBuilder,
    this.skipLoadingOnRefresh = true,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: skipLoadingOnRefresh,
      data: (d) {
        if (empty != null && emptyBuilder != null && empty!(d)) {
          return emptyBuilder!();
        }
        return data(d);
      },
      loading: () => loading ?? const Center(child: LoadingIndicator()),
      error: (e, st) => error != null
          ? error!(e, st)
          : ErrorPlaceholder(message: e.toString(), onRetry: onRetry),
    );
  }
}
