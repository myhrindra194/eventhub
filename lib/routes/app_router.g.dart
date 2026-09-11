// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The application router.
///
/// Composition:
///  * two [StatefulShellRoute]s — one per role — so each tab owns an
///    independent navigation stack;
///  * every "leaf" route (detail, form, participants) is attached to the
///    root navigator so it slides over the navigation bar;
///  * navigation policy lives in [RouteGuard], not here.
///
/// The router instance is `keepAlive`: rebuilding it would reset the whole
/// navigation state, so session changes are pushed through a
/// [RouterRefresh] listenable instead.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// The application router.
///
/// Composition:
///  * two [StatefulShellRoute]s — one per role — so each tab owns an
///    independent navigation stack;
///  * every "leaf" route (detail, form, participants) is attached to the
///    root navigator so it slides over the navigation bar;
///  * navigation policy lives in [RouteGuard], not here.
///
/// The router instance is `keepAlive`: rebuilding it would reset the whole
/// navigation state, so session changes are pushed through a
/// [RouterRefresh] listenable instead.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The application router.
  ///
  /// Composition:
  ///  * two [StatefulShellRoute]s — one per role — so each tab owns an
  ///    independent navigation stack;
  ///  * every "leaf" route (detail, form, participants) is attached to the
  ///    root navigator so it slides over the navigation bar;
  ///  * navigation policy lives in [RouteGuard], not here.
  ///
  /// The router instance is `keepAlive`: rebuilding it would reset the whole
  /// navigation state, so session changes are pushed through a
  /// [RouterRefresh] listenable instead.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'fd3bc00af09ee79345344d01a4b1d7b6a04a48f3';
