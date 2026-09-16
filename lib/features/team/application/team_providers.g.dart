// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamRepository)
final teamRepositoryProvider = TeamRepositoryProvider._();

final class TeamRepositoryProvider
    extends $FunctionalProvider<TeamRepository, TeamRepository, TeamRepository>
    with $Provider<TeamRepository> {
  TeamRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeamRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamRepository create(Ref ref) {
    return teamRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamRepository>(value),
    );
  }
}

String _$teamRepositoryHash() => r'1c179404d1fb7b6d06a74bdf4ad6c74e1adee8b0';

@ProviderFor(eventPendingInvitations)
final eventPendingInvitationsProvider = EventPendingInvitationsFamily._();

final class EventPendingInvitationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffInvitation>>,
          List<StaffInvitation>,
          Stream<List<StaffInvitation>>
        >
    with
        $FutureModifier<List<StaffInvitation>>,
        $StreamProvider<List<StaffInvitation>> {
  EventPendingInvitationsProvider._({
    required EventPendingInvitationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventPendingInvitationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventPendingInvitationsHash();

  @override
  String toString() {
    return r'eventPendingInvitationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<StaffInvitation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StaffInvitation>> create(Ref ref) {
    final argument = this.argument as String;
    return eventPendingInvitations(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventPendingInvitationsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventPendingInvitationsHash() =>
    r'b08e4ceddf13e077cdf68f6a5627009f8dadde7a';

final class EventPendingInvitationsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<StaffInvitation>>, String> {
  EventPendingInvitationsFamily._()
    : super(
        retry: null,
        name: r'eventPendingInvitationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventPendingInvitationsProvider call(String eventId) =>
      EventPendingInvitationsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventPendingInvitationsProvider';
}

/// Invitations en attente de la réponse de l’organisateur connecté.

@ProviderFor(myStaffInvitations)
final myStaffInvitationsProvider = MyStaffInvitationsProvider._();

/// Invitations en attente de la réponse de l’organisateur connecté.

final class MyStaffInvitationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffInvitation>>,
          List<StaffInvitation>,
          Stream<List<StaffInvitation>>
        >
    with
        $FutureModifier<List<StaffInvitation>>,
        $StreamProvider<List<StaffInvitation>> {
  /// Invitations en attente de la réponse de l’organisateur connecté.
  MyStaffInvitationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myStaffInvitationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myStaffInvitationsHash();

  @$internal
  @override
  $StreamProviderElement<List<StaffInvitation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StaffInvitation>> create(Ref ref) {
    return myStaffInvitations(ref);
  }
}

String _$myStaffInvitationsHash() =>
    r'0459d49f3f3ca31c8c75a27a03b6a8be55f52caa';

@ProviderFor(TeamController)
final teamControllerProvider = TeamControllerProvider._();

final class TeamControllerProvider
    extends $AsyncNotifierProvider<TeamController, void> {
  TeamControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamControllerHash();

  @$internal
  @override
  TeamController create() => TeamController();
}

String _$teamControllerHash() => r'982a92a7b0e27873094d557171714231eb53c54c';

abstract class _$TeamController extends $AsyncNotifier<void> {
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
