// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organizer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Toutes les réservations sur les événements de l’organisateur connecté,
/// tous statuts confondus.

@ProviderFor(organizerReservations)
final organizerReservationsProvider = OrganizerReservationsProvider._();

/// Toutes les réservations sur les événements de l’organisateur connecté,
/// tous statuts confondus.

final class OrganizerReservationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reservation>>,
          List<Reservation>,
          Stream<List<Reservation>>
        >
    with
        $FutureModifier<List<Reservation>>,
        $StreamProvider<List<Reservation>> {
  /// Toutes les réservations sur les événements de l’organisateur connecté,
  /// tous statuts confondus.
  OrganizerReservationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizerReservationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizerReservationsHash();

  @$internal
  @override
  $StreamProviderElement<List<Reservation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Reservation>> create(Ref ref) {
    return organizerReservations(ref);
  }
}

String _$organizerReservationsHash() =>
    r'a9daf6f7991863fab3dd0d2ddc6cda3c33e7d1aa';

@ProviderFor(organizerStats)
final organizerStatsProvider = OrganizerStatsProvider._();

final class OrganizerStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrganizerStats>,
          AsyncValue<OrganizerStats>,
          AsyncValue<OrganizerStats>
        >
    with $Provider<AsyncValue<OrganizerStats>> {
  OrganizerStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizerStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizerStatsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<OrganizerStats>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<OrganizerStats> create(Ref ref) {
    return organizerStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<OrganizerStats> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<OrganizerStats>>(value),
    );
  }
}

String _$organizerStatsHash() => r'88949b05b712480c784c86c8e8f4b40b162223e2';

/// Événements à venir qui demandent attention — pilote aussi la pastille de
/// l’onglet « Alertes ».

@ProviderFor(organizerWatchlist)
final organizerWatchlistProvider = OrganizerWatchlistProvider._();

/// Événements à venir qui demandent attention — pilote aussi la pastille de
/// l’onglet « Alertes ».

final class OrganizerWatchlistProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrganizerAlert>>,
          AsyncValue<List<OrganizerAlert>>,
          AsyncValue<List<OrganizerAlert>>
        >
    with $Provider<AsyncValue<List<OrganizerAlert>>> {
  /// Événements à venir qui demandent attention — pilote aussi la pastille de
  /// l’onglet « Alertes ».
  OrganizerWatchlistProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizerWatchlistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizerWatchlistHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<OrganizerAlert>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<OrganizerAlert>> create(Ref ref) {
    return organizerWatchlist(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<OrganizerAlert>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<OrganizerAlert>>>(
        value,
      ),
    );
  }
}

String _$organizerWatchlistHash() =>
    r'1a5da88e0c3361283ecfc523b4b4beb8aa674d4a';

@ProviderFor(organizerActivity)
final organizerActivityProvider = OrganizerActivityProvider._();

final class OrganizerActivityProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrganizerAlert>>,
          AsyncValue<List<OrganizerAlert>>,
          AsyncValue<List<OrganizerAlert>>
        >
    with $Provider<AsyncValue<List<OrganizerAlert>>> {
  OrganizerActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizerActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizerActivityHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<OrganizerAlert>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<OrganizerAlert>> create(Ref ref) {
    return organizerActivity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<OrganizerAlert>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<OrganizerAlert>>>(
        value,
      ),
    );
  }
}

String _$organizerActivityHash() => r'762bc9b6ced3152c1805d79fccca7e84d841beba';
