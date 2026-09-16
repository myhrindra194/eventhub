// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Parcours de création / modification. [existingEventId] == null signifie
/// « création ».
///
/// La couverture est une URL https saisie dans le formulaire (voir
/// [EventDraft.imageUrl]) : sur le plan Spark, il n’y a pas de Cloud
/// Storage vers lequel envoyer un fichier, et un événement sans couverture
/// conserve son visuel généré.

@ProviderFor(EventFormController)
final eventFormControllerProvider = EventFormControllerProvider._();

/// Parcours de création / modification. [existingEventId] == null signifie
/// « création ».
///
/// La couverture est une URL https saisie dans le formulaire (voir
/// [EventDraft.imageUrl]) : sur le plan Spark, il n’y a pas de Cloud
/// Storage vers lequel envoyer un fichier, et un événement sans couverture
/// conserve son visuel généré.
final class EventFormControllerProvider
    extends $AsyncNotifierProvider<EventFormController, void> {
  /// Parcours de création / modification. [existingEventId] == null signifie
  /// « création ».
  ///
  /// La couverture est une URL https saisie dans le formulaire (voir
  /// [EventDraft.imageUrl]) : sur le plan Spark, il n’y a pas de Cloud
  /// Storage vers lequel envoyer un fichier, et un événement sans couverture
  /// conserve son visuel généré.
  EventFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventFormControllerHash();

  @$internal
  @override
  EventFormController create() => EventFormController();
}

String _$eventFormControllerHash() =>
    r'c03a0b5256c5f546ad6a8ca02a689e9b23ffdd38';

/// Parcours de création / modification. [existingEventId] == null signifie
/// « création ».
///
/// La couverture est une URL https saisie dans le formulaire (voir
/// [EventDraft.imageUrl]) : sur le plan Spark, il n’y a pas de Cloud
/// Storage vers lequel envoyer un fichier, et un événement sans couverture
/// conserve son visuel généré.

abstract class _$EventFormController extends $AsyncNotifier<void> {
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

/// Actions destructrices sur un événement existant.

@ProviderFor(EventActionsController)
final eventActionsControllerProvider = EventActionsControllerProvider._();

/// Actions destructrices sur un événement existant.
final class EventActionsControllerProvider
    extends $AsyncNotifierProvider<EventActionsController, void> {
  /// Actions destructrices sur un événement existant.
  EventActionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventActionsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventActionsControllerHash();

  @$internal
  @override
  EventActionsController create() => EventActionsController();
}

String _$eventActionsControllerHash() =>
    r'dd65922f339e9e9423a9632a579ae07e05698fa3';

/// Actions destructrices sur un événement existant.

abstract class _$EventActionsController extends $AsyncNotifier<void> {
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
