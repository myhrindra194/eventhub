import 'dart:async';

import 'package:eventhub/core/utils/app_logger.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_analytics.g.dart';

/// L’analytique produit, derrière un vocabulaire unique.
///
/// Deux règles la rendent sûre à appeler de n’importe où :
///  * elle ne lève jamais et n’attend jamais dans le chemin de l’appelant —
///    l’analytique ne doit pas casser une réservation, et les tests tournent
///    sans app Firebase ;
///  * elle ne collecte rien tant que l’utilisateur n’a pas accepté
///    ([setCollectionEnabled], piloté par `AnalyticsConsent` ; la collecte
///    est désactivée par défaut dans AndroidManifest.xml et Info.plist).
///
/// Les noms d’événements reprennent les événements recommandés par Firebase
/// lorsqu’il en existe un (`login`, `sign_up`, `share`, `add_to_wishlist`),
/// et sinon un snake_case maison.
class AppAnalytics {
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> setCollectionEnabled(bool enabled) async {
    _fire(() => _analytics.setAnalyticsCollectionEnabled(enabled));
  }

  void screen(String name) =>
      _fire(() => _analytics.logScreenView(screenName: name));

  /// Rattache l’analytique et les rapports de crash au compte (uniquement
  /// l’uid Firebase, ni email ni nom).
  void identify({required String? userId, String? role}) {
    _fire(() => _analytics.setUserId(id: userId));
    _fire(() => _analytics.setUserProperty(name: 'role', value: role));
    if (!kIsWeb) {
      _fire(() => FirebaseCrashlytics.instance.setUserIdentifier(userId ?? ''));
    }
  }

  void login(String method) =>
      _fire(() => _analytics.logLogin(loginMethod: method));

  void signUp(String method) =>
      _fire(() => _analytics.logSignUp(signUpMethod: method));

  void eventPublished(String eventId) =>
      _event('event_published', {'event_id': eventId});

  void reservationConfirmed(String eventId) =>
      _event('reservation_confirmed', {'event_id': eventId});

  /// Le `begin_checkout` recommandé par Firebase (l’achat lui-même est
  /// confirmé côté serveur par le webhook Stripe).
  void checkoutStarted(String eventId, String tierId) => _fire(
    () => _analytics.logBeginCheckout(
      items: [AnalyticsEventItem(itemId: eventId, itemVariant: tierId)],
    ),
  );

  void reservationCancelled(String eventId) =>
      _event('reservation_cancelled', {'event_id': eventId});

  void share(String eventId, String method) => _fire(
    () => _analytics.logShare(
      contentType: 'event',
      itemId: eventId,
      method: method,
    ),
  );

  void favorite(String eventId, {required bool added}) => added
      ? _fire(
          () => _analytics.logAddToWishlist(
            items: [AnalyticsEventItem(itemId: eventId)],
          ),
        )
      : _event('remove_from_wishlist', {'event_id': eventId});

  void waitlistJoined(String eventId) =>
      _event('waitlist_joined', {'event_id': eventId});

  void reviewPublished(String eventId, int rating) =>
      _event('review_published', {'event_id': eventId, 'rating': rating});

  void ticketScanned(String status) =>
      _event('ticket_scanned', {'status': status});

  void follow(String organizerId, {required bool added}) => _event(
    added ? 'organizer_followed' : 'organizer_unfollowed',
    {'organizer_id': organizerId},
  );

  /// Type de cible et motif uniquement — jamais le contenu signalé ni son id.
  void contentReported(String targetType, String reason) =>
      _event('content_reported', {'target_type': targetType, 'reason': reason});

  void _event(String name, Map<String, Object> parameters) =>
      _fire(() => _analytics.logEvent(name: name, parameters: parameters));

  void _fire(Future<void> Function() call) {
    try {
      unawaited(
        call().catchError((Object e) => AppLogger.debug('analytics: $e')),
      );
    } on Object catch (e) {
      // Pas d’app Firebase (tests) ou plateforme non supportée.
      AppLogger.debug('analytics unavailable: $e');
    }
  }
}

@Riverpod(keepAlive: true)
AppAnalytics appAnalytics(Ref ref) => AppAnalytics();
