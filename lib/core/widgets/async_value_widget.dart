import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an [AsyncValue] with consistent loading / error / empty states.
///
/// Keeps the previous data visible while refreshing (Riverpod `isRefreshing`)
/// so lists don't flash a spinner on every Firestore snapshot.
///
/// Set [sliver] when used inside a `CustomScrollView`: state views are then
/// wrapped in a `SliverFillRemaining` and [data]/[empty]/[loading] must
/// return slivers.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    required this.value,
    required this.data,
    super.key,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.loading,
    this.sliver = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// When provided and true for the current data, [empty] is shown instead.
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;
  final bool sliver;

  Widget _wrap(Widget child) =>
      sliver ? SliverFillRemaining(hasScrollBody: false, child: child) : child;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue && !value.hasError) {
      final current = value.requireValue;
      if (isEmpty?.call(current) ?? false) {
        return empty ?? _wrap(const EmptyStateView(message: 'Aucun élément.'));
      }
      return data(current);
    }
    if (value.hasError) {
      final error = value.error;
      final message = error is Failure ? error.message : error.toString();
      return _wrap(ErrorStateView(message: message, onRetry: onRetry));
    }
    return loading ?? _wrap(const LoadingStateView());
  }
}
