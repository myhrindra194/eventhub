import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rend un [AsyncValue] avec des états de chargement, d'erreur et de vide
/// cohérents dans toute l'application.
///
/// Garde les données précédentes à l'écran pendant un rafraîchissement
/// (`isRefreshing` de Riverpod), pour qu'une liste ne fasse pas clignoter un
/// indicateur de chargement à chaque snapshot Firestore.
///
/// Passe [sliver] à `true` dans un `CustomScrollView` : les vues d'état sont
/// alors enveloppées dans un `SliverFillRemaining`, et [data], [empty] et
/// [loading] doivent renvoyer des slivers.
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

  /// Fourni et vrai pour les données courantes, [empty] s'affiche à leur
  /// place.
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
