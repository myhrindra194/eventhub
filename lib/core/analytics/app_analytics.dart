import 'dart:async';

import 'package:eventhub/core/utils/app_logger.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_analytics.g.dart';

/// Product analytics, behind one vocabulary.
///
/// Two rules make it safe to call from anywhere:
///  * it never throws and never awaits in the caller's path — analytics must
///    not break a booking, and tests run without a Firebase app;
///  * it collects nothing until the user agreed ([setCollectionEnabled],
///    driven by `AnalyticsConsent`; collection is disabled by default in
///    AndroidManifest.xml and Info.plist).
///
/// Event names follow Firebase's recommended events where one exists
/// (`login`, `sign_up`, `share`, `add_to_wishlist`), custom snake_case
/// otherwise.
class AppAnalytics {
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> setCollectionEnabled(bool enabled) async {
    _fire(() => _analytics.setAnalyticsCollectionEnabled(enabled));
  }

  void screen(String name) =>
      _fire(() => _analytics.logScreenView(screenName: name));

  /// Ties analytics and crash reports to the account (Firebase uid only, no
  /// email or name).
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

  void _event(String name, Map<String, Object> parameters) =>
      _fire(() => _analytics.logEvent(name: name, parameters: parameters));

  void _fire(Future<void> Function() call) {
    try {
      unawaited(
        call().catchError((Object e) => AppLogger.debug('analytics: $e')),
      );
    } on Object catch (e) {
      // No Firebase app (tests) or unsupported platform.
      AppLogger.debug('analytics unavailable: $e');
    }
  }
}

@Riverpod(keepAlive: true)
AppAnalytics appAnalytics(Ref ref) => AppAnalytics();
