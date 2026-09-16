// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationRepository)
final notificationRepositoryProvider = NotificationRepositoryProvider._();

final class NotificationRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationRepository,
          NotificationRepository,
          NotificationRepository
        >
    with $Provider<NotificationRepository> {
  NotificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationRepository create(Ref ref) {
    return notificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationRepository>(value),
    );
  }
}

String _$notificationRepositoryHash() =>
    r'2980df71856bc086a8f4dcf3738eca5d5b484e05';

@ProviderFor(pushMessaging)
final pushMessagingProvider = PushMessagingProvider._();

final class PushMessagingProvider
    extends
        $FunctionalProvider<
          PushMessagingDataSource,
          PushMessagingDataSource,
          PushMessagingDataSource
        >
    with $Provider<PushMessagingDataSource> {
  PushMessagingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushMessagingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushMessagingHash();

  @$internal
  @override
  $ProviderElement<PushMessagingDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushMessagingDataSource create(Ref ref) {
    return pushMessaging(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushMessagingDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushMessagingDataSource>(value),
    );
  }
}

String _$pushMessagingHash() => r'ed72692e7edf4cf64e67ee49512f56638b997db5';

@ProviderFor(localNotifications)
final localNotificationsProvider = LocalNotificationsProvider._();

final class LocalNotificationsProvider
    extends
        $FunctionalProvider<
          LocalNotificationDataSource,
          LocalNotificationDataSource,
          LocalNotificationDataSource
        >
    with $Provider<LocalNotificationDataSource> {
  LocalNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localNotificationsHash();

  @$internal
  @override
  $ProviderElement<LocalNotificationDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalNotificationDataSource create(Ref ref) {
    return localNotifications(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalNotificationDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalNotificationDataSource>(value),
    );
  }
}

String _$localNotificationsHash() =>
    r'2016fd7d441d36238311b5d93deffd2f29a8c593';

/// Préférences de l’utilisateur connecté ; valeurs par défaut hors session.

@ProviderFor(notificationPreferences)
final notificationPreferencesProvider = NotificationPreferencesProvider._();

/// Préférences de l’utilisateur connecté ; valeurs par défaut hors session.

final class NotificationPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationPreferences>,
          NotificationPreferences,
          Stream<NotificationPreferences>
        >
    with
        $FutureModifier<NotificationPreferences>,
        $StreamProvider<NotificationPreferences> {
  /// Préférences de l’utilisateur connecté ; valeurs par défaut hors session.
  NotificationPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPreferencesHash();

  @$internal
  @override
  $StreamProviderElement<NotificationPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<NotificationPreferences> create(Ref ref) {
    return notificationPreferences(ref);
  }
}

String _$notificationPreferencesHash() =>
    r'a22ab2bcb22a2b7a2038352a033ce0eeaf891200';

@ProviderFor(NotificationPreferencesController)
final notificationPreferencesControllerProvider =
    NotificationPreferencesControllerProvider._();

final class NotificationPreferencesControllerProvider
    extends $AsyncNotifierProvider<NotificationPreferencesController, void> {
  NotificationPreferencesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPreferencesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$notificationPreferencesControllerHash();

  @$internal
  @override
  NotificationPreferencesController create() =>
      NotificationPreferencesController();
}

String _$notificationPreferencesControllerHash() =>
    r'786523c7745679dc575239cd67378a0d8fd74389';

abstract class _$NotificationPreferencesController
    extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Historique in-app de l’utilisateur connecté, le plus récent d’abord.

@ProviderFor(notificationFeed)
final notificationFeedProvider = NotificationFeedProvider._();

/// Historique in-app de l’utilisateur connecté, le plus récent d’abord.

final class NotificationFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppNotification>>,
          List<AppNotification>,
          Stream<List<AppNotification>>
        >
    with
        $FutureModifier<List<AppNotification>>,
        $StreamProvider<List<AppNotification>> {
  /// Historique in-app de l’utilisateur connecté, le plus récent d’abord.
  NotificationFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationFeedHash();

  @$internal
  @override
  $StreamProviderElement<List<AppNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppNotification>> create(Ref ref) {
    return notificationFeed(ref);
  }
}

String _$notificationFeedHash() => r'86b9aa98b880e619a1baff5a547606547ac05db7';

/// Pilote la pastille de tous les boutons cloche.

@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = UnreadNotificationCountProvider._();

/// Pilote la pastille de tous les boutons cloche.

final class UnreadNotificationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Pilote la pastille de tous les boutons cloche.
  UnreadNotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadNotificationCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unreadNotificationCountHash() =>
    r'f08f274adc2ed89fd5f3e3bf6d88ddcb338d2c0b';

@ProviderFor(NotificationFeedController)
final notificationFeedControllerProvider =
    NotificationFeedControllerProvider._();

final class NotificationFeedControllerProvider
    extends $AsyncNotifierProvider<NotificationFeedController, void> {
  NotificationFeedControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationFeedControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationFeedControllerHash();

  @$internal
  @override
  NotificationFeedController create() => NotificationFeedController();
}

String _$notificationFeedControllerHash() =>
    r'd16c22f46c9a0d3b033eb93e435f9364087473e0';

abstract class _$NotificationFeedController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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

@ProviderFor(PushNotifications)
final pushNotificationsProvider = PushNotificationsProvider._();

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
final class PushNotificationsProvider
    extends $NotifierProvider<PushNotifications, void> {
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
  PushNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotificationsHash();

  @$internal
  @override
  PushNotifications create() => PushNotifications();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushNotificationsHash() => r'32c0bf3e77c487ef72b0a7349c7badcea2a126c8';

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

abstract class _$PushNotifications extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
