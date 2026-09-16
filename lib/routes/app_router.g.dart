// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le router de l’application.
///
/// Composition :
///  * deux [StatefulShellRoute] — un par rôle — pour que chaque onglet
///    possède une pile de navigation indépendante ;
///  * toute route « feuille » (détail, formulaire, participants) est
///    rattachée au navigator racine afin de glisser par-dessus la barre de
///    navigation ;
///  * la politique de navigation vit dans [RouteGuard], pas ici.
///
/// L’instance du router est `keepAlive` : la reconstruire réinitialiserait
/// tout l’état de navigation ; les changements de session sont donc poussés
/// via un listenable [RouterRefresh].

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Le router de l’application.
///
/// Composition :
///  * deux [StatefulShellRoute] — un par rôle — pour que chaque onglet
///    possède une pile de navigation indépendante ;
///  * toute route « feuille » (détail, formulaire, participants) est
///    rattachée au navigator racine afin de glisser par-dessus la barre de
///    navigation ;
///  * la politique de navigation vit dans [RouteGuard], pas ici.
///
/// L’instance du router est `keepAlive` : la reconstruire réinitialiserait
/// tout l’état de navigation ; les changements de session sont donc poussés
/// via un listenable [RouterRefresh].

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Le router de l’application.
  ///
  /// Composition :
  ///  * deux [StatefulShellRoute] — un par rôle — pour que chaque onglet
  ///    possède une pile de navigation indépendante ;
  ///  * toute route « feuille » (détail, formulaire, participants) est
  ///    rattachée au navigator racine afin de glisser par-dessus la barre de
  ///    navigation ;
  ///  * la politique de navigation vit dans [RouteGuard], pas ici.
  ///
  /// L’instance du router est `keepAlive` : la reconstruire réinitialiserait
  /// tout l’état de navigation ; les changements de session sont donc poussés
  /// via un listenable [RouterRefresh].
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

String _$appRouterHash() => r'31f8b53e25d9aa5e8dbcf9f89d2f37c952c5b4c7';
