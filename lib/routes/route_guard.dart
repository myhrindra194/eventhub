import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter/foundation.dart';

/// Résultat de la séquence de démarrage, du point de vue de la navigation.
///
/// Modélisé explicitement (plutôt que de jongler avec deux `AsyncValue` au
/// cœur du callback de redirection) pour que toute la politique de navigation
/// devienne une fonction pure d’un objet valeur — et donc testable
/// unitairement sans arbre de widgets.
@immutable
class RouteGuardState {
  const RouteGuardState({
    required this.session,
    required this.onboardingSeen,
    required this.isBooting,
  });

  /// `null` tant que le flux de session n’a rien émis.
  final AuthSession? session;

  /// `null` tant que la préférence n’a pas encore été lue.
  final bool? onboardingSeen;

  /// Vrai tant que l’une des deux valeurs ci-dessus reste inconnue lors d’un
  /// démarrage à froid.
  final bool isBooting;

  @override
  bool operator ==(Object other) =>
      other is RouteGuardState &&
      other.session == session &&
      other.onboardingSeen == onboardingSeen &&
      other.isBooting == isBooting;

  @override
  int get hashCode => Object.hash(session, onboardingSeen, isBooting);
}

/// L’unique endroit où se décide « qui a le droit de voir quoi ».
///
/// Règles, par ordre de priorité :
///  1. **Démarrage** — on retient tout le monde sur le splash tant que la
///     session et le drapeau d’onboarding ne sont pas connus. Évite que
///     l’écran de connexion n’apparaisse en un éclair à un utilisateur déjà
///     authentifié.
///  2. **Premier lancement** — une installation qui n’a jamais vu
///     l’onboarding y est dirigée avant toute autre chose.
///  3. **Déconnecté** — seules les destinations publiques sont accessibles ;
///     tout le reste retombe sur `/login`.
///  4. **Profil manquant** — un compte Firebase sans profil Firestore est
///     épinglé sur `/complete-profile` (pas d’échappatoire, pas d’impasse).
///  5. **Connecté** — les destinations publiques renvoient vers l’accueil du
///     rôle, et chaque rôle est confiné à son propre espace (`/organizer/**`
///     face au reste) : les deux rôles sont exclusifs.
///
/// **Liens profonds.** Un lien partagé démarre le plus souvent l’application
/// à froid, c’est-à-dire qu’il arrive pendant le démarrage ou hors session.
/// Sa destination voyage dans `?from=` à travers le splash et la connexion,
/// puis remplace l’accueil du rôle une fois connecté (règle 5). Seules les
/// destinations reconnues par [AppRoutes.isDeepLinkTarget] sont honorées :
/// `from` vient de l’extérieur et ne doit pas pouvoir ouvrir un écran
/// arbitraire.
///
/// Renvoyer `null` signifie « la destination demandée convient, on la laisse
/// passer ».
abstract final class RouteGuard {
  static String? redirect({
    required RouteGuardState state,
    required String location,
    String? from,
  }) {
    final pending = from != null && AppRoutes.isDeepLinkTarget(from)
        ? from
        : null;

    // 1. Démarrage à froid : on ne sait encore rien.
    if (state.isBooting) {
      if (location == AppRoutes.splash) return null;
      return AppRoutes.isDeepLinkTarget(location)
          ? AppRoutes.withFrom(AppRoutes.splash, location)
          : AppRoutes.splash;
    }

    return switch (state.session) {
      null || SignedOut() => _signedOut(state, location, pending),
      ProfileMissing() =>
        location == AppRoutes.completeProfile
            ? null
            : AppRoutes.completeProfile,
      SignedIn(:final user) => _signedIn(
        location: location,
        home: user.role.homePath,
        isOrganizer: user.isOrganizer,
        isAdmin: user.isAdmin,
        pending: pending,
      ),
    };
  }

  static String? _signedOut(
    RouteGuardState state,
    String location,
    String? pending,
  ) {
    // 2. Premier lancement sur cette installation.
    if (!(state.onboardingSeen ?? true)) {
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }
    // Onboarding déjà consommé : ce n’est plus une destination valide.
    if (location == AppRoutes.onboarding) return AppRoutes.login;

    // 3. Les destinations publiques restent accessibles ; le splash, lui,
    // n’est que transitoire.
    final isReachable =
        AppRoutes.isPublic(location) && location != AppRoutes.splash;
    if (isReachable) return null;

    final resume = AppRoutes.isDeepLinkTarget(location) ? location : pending;
    return resume == null
        ? AppRoutes.login
        : AppRoutes.withFrom(AppRoutes.login, resume);
  }

  static String? _signedIn({
    required String location,
    required String home,
    required bool isOrganizer,
    required bool isAdmin,
    required String? pending,
  }) {
    // L’administration se situe hors des deux espaces de rôle et exige le
    // claim `admin`. Masquer les écrans n’est qu’un confort : sans le claim,
    // chaque lecture est refusée par les règles et chaque décision par la
    // callable.
    if (AppRoutes.isAdminArea(location)) return isAdmin ? null : home;

    // Les écrans partagés par les deux rôles (la célébration d’après
    // inscription, le changement de mot de passe, les profils publics
    // d’organisateurs) court-circuitent la règle de confinement ci-dessous.
    if (AppRoutes.isRoleAgnostic(location)) return null;

    // Le compte existe : l’entonnoir d’inscription est terminé.
    if (location == AppRoutes.register ||
        location == AppRoutes.completeProfile) {
      return AppRoutes.welcome;
    }

    // 5. Plus de retour vers l’entonnoir public une fois authentifié — on
    // reprend le lien qui a amené l’utilisateur ici, s’il y en a un. Le
    // confinement par rôle s’y appliquera quand même à la passe suivante.
    if (AppRoutes.isPublic(location)) return pending ?? home;

    // Un lien partagé : `/e/{id}` redirige vers le détail de l’événement au
    // niveau des routes.
    if (location.startsWith('/e/')) return null;

    // Deux rôles exclusifs, fixés à l’inscription : chacun reste dans son
    // espace. Un participant n’entre pas dans l’espace organisateur ; un
    // organisateur ne réserve pas et reste dans le sien.
    if (AppRoutes.isOrganizerArea(location) != isOrganizer) return home;

    return null;
  }
}
