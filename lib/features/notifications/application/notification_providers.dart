import 'dart:async';

import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/notifications/application/notification_route.dart';
import 'package:eventhub/features/notifications/data/local_notification_data_source.dart';
import 'package:eventhub/features/notifications/data/notification_remote_data_source.dart';
import 'package:eventhub/features/notifications/data/notification_repository_impl.dart';
import 'package:eventhub/features/notifications/data/push_messaging_data_source.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:eventhub/features/notifications/domain/notification_repository.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'notification_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepositoryImpl(
      NotificationRemoteDataSource(ref.watch(firestoreProvider)),
    );

@Riverpod(keepAlive: true)
PushMessagingDataSource pushMessaging(Ref ref) =>
    PushMessagingDataSource(ref.watch(firebaseMessagingProvider));

@Riverpod(keepAlive: true)
LocalNotificationDataSource localNotifications(Ref ref) =>
    LocalNotificationDataSource();

/// Préférences de l’utilisateur connecté ; valeurs par défaut hors session.
@riverpod
Stream<NotificationPreferences> notificationPreferences(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const NotificationPreferences());
  return ref.watch(notificationRepositoryProvider).watchPreferences(user.id);
}

@riverpod
class NotificationPreferencesController
    extends _$NotificationPreferencesController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> save(NotificationPreferences preferences) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    state = const AsyncLoading();
    final result = await ref
        .read(notificationRepositoryProvider)
        .savePreferences(userId: user.id, preferences: preferences);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    return result;
  }
}

/// Historique in-app de l’utilisateur connecté, le plus récent d’abord.
@riverpod
Stream<List<AppNotification>> notificationFeed(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
}

/// Pilote la pastille de tous les boutons cloche.
@riverpod
int unreadNotificationCount(Ref ref) =>
    ref.watch(notificationFeedProvider).value?.where((n) => !n.isRead).length ??
    0;

@riverpod
class NotificationFeedController extends _$NotificationFeedController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> markRead(AppNotification notification) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    if (notification.isRead) return const Ok(null);
    return ref
        .read(notificationRepositoryProvider)
        .markRead(userId: user.id, notificationId: notification.id);
  }

  Future<Result<void>> markAllRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    // Rien de non lu dans le fil : on évite l’aller-retour. L’instruction
    // serveur, elle, ne dépend pas des identifiants affichés (voir le
    // repository).
    final feed = ref.read(notificationFeedProvider).value;
    if (feed != null && feed.every((n) => n.isRead)) return const Ok(null);
    return ref
        .read(notificationRepositoryProvider)
        .markAllRead(userId: user.id);
  }

  Future<Result<void>> delete(AppNotification notification) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    return ref
        .read(notificationRepositoryProvider)
        .deleteNotification(userId: user.id, notificationId: notification.id);
  }
}

/// Le pipeline push sur l’appareil, piloté par la session.
///
/// * connecté → demander la permission, enregistrer le jeton FCM sous le
///   compte et le maintenir enregistré à chaque rafraîchissement ;
/// * déconnecté → invalider le jeton (voir
///   [PushMessagingDataSource.deleteToken]) ;
/// * message reçu au premier plan → affiché en notification locale ;
/// * appui (premier plan, arrière-plan ou démarrage à froid) →
///   [NotificationRoute].
///
/// Sur le plan Spark, rien n’émet vers ces jetons — un émetteur, c’est du code
/// serveur — ce pipeline ne porte donc que les messages reçus au premier plan
/// et les appuis. L’enregistrement est conservé parce que c’est ce qu’une
/// future Cloud Function irait lire, et qu’il ne coûte qu’un document par
/// installation.
///
/// Pourquoi la déconnexion ne supprime pas le document de l’appareil : ce
/// provider apprend la déconnexion par [currentUserProvider], c’est-à-dire une
/// fois la session déjà perdue, et les règles refusent une suppression
/// anonyme. Invalider le jeton ne demande aucune session et suffit : le
/// document est indexé sur l’installation, donc le prochain compte qui se
/// connecte sur ce téléphone remplace le jeton mort sur place.
///
/// Observé une seule fois par `EventHubApp` ; maintenu en vie pendant toute la
/// durée de l’application. Le web est exclu volontairement : le push web exige
/// une clé VAPID et un service worker.
@Riverpod(keepAlive: true)
class PushNotifications extends _$PushNotifications {
  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<String>? _tokenRefresh;
  String? _userId;

  @override
  void build() {
    // Le push web exige une clé VAPID (console Firebase → Cloud Messaging →
    // Web Push certificates) et web/firebase-messaging-sw.js. Sans cette clé,
    // le build web ne s’enregistre tout simplement pas pour les pushs.
    if (kIsWeb && ref.read(appConfigProvider).webPushVapidKey.isEmpty) return;
    ref.onDispose(() {
      for (final s in _subscriptions) {
        unawaited(s.cancel());
      }
      unawaited(_tokenRefresh?.cancel());
    });

    final messaging = ref.read(pushMessagingProvider);
    final local = ref.read(localNotificationsProvider);

    // Sur le web, le navigateur n’affiche les pushs reçus au premier plan
    // qu’à travers le service worker ; l’historique in-app les couvre à la
    // place.
    if (!kIsWeb) {
      unawaited(local.initialize(onTap: _open));
      _subscriptions.add(messaging.onMessage.listen(local.show));
    }
    _subscriptions.add(
      messaging.onMessageOpenedApp.listen((m) => _open(m.data)),
    );
    unawaited(messaging.getInitialMessage().then(_openInitial));

    ref.listen<AppUser?>(
      currentUserProvider,
      (_, user) => unawaited(_onUserChanged(user)),
      fireImmediately: true,
    );
  }

  Future<void> _onUserChanged(AppUser? user) async {
    if (user?.id == _userId) return;
    final previous = _userId;
    _userId = user?.id;
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;

    final messaging = ref.read(pushMessagingProvider);
    try {
      if (user == null) {
        if (previous != null) await messaging.deleteToken();
        return;
      }
      if (!await messaging.requestPermission()) {
        AppLogger.info('Push permission denied: device not registered');
        return;
      }
      final vapidKey = ref.read(appConfigProvider).webPushVapidKey;
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? vapidKey : null,
      );
      if (token != null) await _register(user.id, token);
      _tokenRefresh = messaging.onTokenRefresh.listen(
        (token) => unawaited(_register(user.id, token)),
      );
    } catch (error, stack) {
      // Le push est un confort : un échec ici ne doit jamais casser la
      // connexion.
      AppLogger.error('Push setup failed', error: error, stackTrace: stack);
    }
  }

  Future<void> _register(String userId, String token) async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .registerDevice(
          userId: userId,
          token: token,
          // L’une des plateformes que les règles acceptent.
          platform: kIsWeb
              ? 'web'
              : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        );
    if (result case Err(:final failure)) {
      AppLogger.warning('Device registration failed', error: failure);
    }
  }

  void _openInitial(RemoteMessage? message) {
    if (message != null) _open(message.data);
  }

  void _open(Map<String, Object?> data) {
    final location = NotificationRoute.locationFor(data);
    if (location == null) return;
    unawaited(ref.read(appRouterProvider).push(location));
  }
}
