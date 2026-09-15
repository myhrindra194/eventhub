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
    r'60dbd6f47408413cd59f523941fb08ba0c57a73d';

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

/// Preferences of the signed-in user; defaults while signed out.

@ProviderFor(notificationPreferences)
final notificationPreferencesProvider = NotificationPreferencesProvider._();

/// Preferences of the signed-in user; defaults while signed out.

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
  /// Preferences of the signed-in user; defaults while signed out.
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

/// In-app history of the signed-in user, most recent first.

@ProviderFor(notificationFeed)
final notificationFeedProvider = NotificationFeedProvider._();

/// In-app history of the signed-in user, most recent first.

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
  /// In-app history of the signed-in user, most recent first.
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

/// Drives the dot on every bell button.

@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = UnreadNotificationCountProvider._();

/// Drives the dot on every bell button.

final class UnreadNotificationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Drives the dot on every bell button.
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

/// The push pipeline on the device, driven by the session.
///
/// * signed in → ask permission, register the FCM token under the user
///   (`public.register_device`), keep it registered on refresh;
/// * signed out → invalidate the token (see
///   [PushMessagingDataSource.deleteToken]);
/// * foreground message → shown as a local notification;
/// * tap (foreground, background or cold start) → [NotificationRoute].
///
/// Why sign-out does not delete the `devices` row: this provider learns of
/// the sign-out from [currentUserProvider], i.e. once the session is already
/// gone, and RLS refuses an anonymous delete. Invalidating the token needs no
/// session and is enough on its own: FCM answers `UNREGISTERED` to the next
/// send and the worker forgets the row (`devices_forget_tokens`). If the
/// device is offline and the invalidation fails, the next account signing in
/// on the phone gets the same token, and `register_device` moves it away from
/// the previous account. The row is keyed by installation, so the same
/// person signing in again replaces the dead token in place.
///
/// Watched once by `EventHubApp`; kept alive for the app's lifetime. Web is
/// excluded on purpose: web push needs a VAPID key and a service worker.

@ProviderFor(PushNotifications)
final pushNotificationsProvider = PushNotificationsProvider._();

/// The push pipeline on the device, driven by the session.
///
/// * signed in → ask permission, register the FCM token under the user
///   (`public.register_device`), keep it registered on refresh;
/// * signed out → invalidate the token (see
///   [PushMessagingDataSource.deleteToken]);
/// * foreground message → shown as a local notification;
/// * tap (foreground, background or cold start) → [NotificationRoute].
///
/// Why sign-out does not delete the `devices` row: this provider learns of
/// the sign-out from [currentUserProvider], i.e. once the session is already
/// gone, and RLS refuses an anonymous delete. Invalidating the token needs no
/// session and is enough on its own: FCM answers `UNREGISTERED` to the next
/// send and the worker forgets the row (`devices_forget_tokens`). If the
/// device is offline and the invalidation fails, the next account signing in
/// on the phone gets the same token, and `register_device` moves it away from
/// the previous account. The row is keyed by installation, so the same
/// person signing in again replaces the dead token in place.
///
/// Watched once by `EventHubApp`; kept alive for the app's lifetime. Web is
/// excluded on purpose: web push needs a VAPID key and a service worker.
final class PushNotificationsProvider
    extends $NotifierProvider<PushNotifications, void> {
  /// The push pipeline on the device, driven by the session.
  ///
  /// * signed in → ask permission, register the FCM token under the user
  ///   (`public.register_device`), keep it registered on refresh;
  /// * signed out → invalidate the token (see
  ///   [PushMessagingDataSource.deleteToken]);
  /// * foreground message → shown as a local notification;
  /// * tap (foreground, background or cold start) → [NotificationRoute].
  ///
  /// Why sign-out does not delete the `devices` row: this provider learns of
  /// the sign-out from [currentUserProvider], i.e. once the session is already
  /// gone, and RLS refuses an anonymous delete. Invalidating the token needs no
  /// session and is enough on its own: FCM answers `UNREGISTERED` to the next
  /// send and the worker forgets the row (`devices_forget_tokens`). If the
  /// device is offline and the invalidation fails, the next account signing in
  /// on the phone gets the same token, and `register_device` moves it away from
  /// the previous account. The row is keyed by installation, so the same
  /// person signing in again replaces the dead token in place.
  ///
  /// Watched once by `EventHubApp`; kept alive for the app's lifetime. Web is
  /// excluded on purpose: web push needs a VAPID key and a service worker.
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

/// The push pipeline on the device, driven by the session.
///
/// * signed in → ask permission, register the FCM token under the user
///   (`public.register_device`), keep it registered on refresh;
/// * signed out → invalidate the token (see
///   [PushMessagingDataSource.deleteToken]);
/// * foreground message → shown as a local notification;
/// * tap (foreground, background or cold start) → [NotificationRoute].
///
/// Why sign-out does not delete the `devices` row: this provider learns of
/// the sign-out from [currentUserProvider], i.e. once the session is already
/// gone, and RLS refuses an anonymous delete. Invalidating the token needs no
/// session and is enough on its own: FCM answers `UNREGISTERED` to the next
/// send and the worker forgets the row (`devices_forget_tokens`). If the
/// device is offline and the invalidation fails, the next account signing in
/// on the phone gets the same token, and `register_device` moves it away from
/// the previous account. The row is keyed by installation, so the same
/// person signing in again replaces the dead token in place.
///
/// Watched once by `EventHubApp`; kept alive for the app's lifetime. Web is
/// excluded on purpose: web push needs a VAPID key and a service worker.

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
