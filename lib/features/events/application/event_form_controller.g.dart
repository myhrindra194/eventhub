// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Create / update flow. [existingEventId] == null means "create".
///
/// The cover is an https URL typed in the form (see [EventDraft.imageUrl]):
/// on the Spark plan there is no Cloud Storage to upload to, and an event
/// without a cover keeps its generated visual.

@ProviderFor(EventFormController)
final eventFormControllerProvider = EventFormControllerProvider._();

/// Create / update flow. [existingEventId] == null means "create".
///
/// The cover is an https URL typed in the form (see [EventDraft.imageUrl]):
/// on the Spark plan there is no Cloud Storage to upload to, and an event
/// without a cover keeps its generated visual.
final class EventFormControllerProvider
    extends $AsyncNotifierProvider<EventFormController, void> {
  /// Create / update flow. [existingEventId] == null means "create".
  ///
  /// The cover is an https URL typed in the form (see [EventDraft.imageUrl]):
  /// on the Spark plan there is no Cloud Storage to upload to, and an event
  /// without a cover keeps its generated visual.
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

/// Create / update flow. [existingEventId] == null means "create".
///
/// The cover is an https URL typed in the form (see [EventDraft.imageUrl]):
/// on the Spark plan there is no Cloud Storage to upload to, and an event
/// without a cover keeps its generated visual.

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

/// Destructive actions on an existing event.

@ProviderFor(EventActionsController)
final eventActionsControllerProvider = EventActionsControllerProvider._();

/// Destructive actions on an existing event.
final class EventActionsControllerProvider
    extends $AsyncNotifierProvider<EventActionsController, void> {
  /// Destructive actions on an existing event.
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

/// Destructive actions on an existing event.

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
