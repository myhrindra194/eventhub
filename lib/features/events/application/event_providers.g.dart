// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventRepository)
final eventRepositoryProvider = EventRepositoryProvider._();

final class EventRepositoryProvider
    extends
        $FunctionalProvider<EventRepository, EventRepository, EventRepository>
    with $Provider<EventRepository> {
  EventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventRepository create(Ref ref) {
    return eventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventRepository>(value),
    );
  }
}

String _$eventRepositoryHash() => r'e2fe9819abf84eaf0a027fecbbe49a3419790d8c';

/// Première page des événements à venir, en temps réel (ceux du jour
/// restent visibles jusqu’à minuit).

@ProviderFor(upcomingEvents)
final upcomingEventsProvider = UpcomingEventsProvider._();

/// Première page des événements à venir, en temps réel (ceux du jour
/// restent visibles jusqu’à minuit).

final class UpcomingEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  /// Première page des événements à venir, en temps réel (ceux du jour
  /// restent visibles jusqu’à minuit).
  UpcomingEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Event>> create(Ref ref) {
    return upcomingEvents(ref);
  }
}

String _$upcomingEventsHash() => r'747d1ccbb4f1d42f60e1233fa611f39b640c5be7';

/// Pages plus anciennes du catalogue, chargées quand l’utilisateur atteint
/// la fin de la liste.

@ProviderFor(CatalogueExtraPages)
final catalogueExtraPagesProvider = CatalogueExtraPagesProvider._();

/// Pages plus anciennes du catalogue, chargées quand l’utilisateur atteint
/// la fin de la liste.
final class CatalogueExtraPagesProvider
    extends $NotifierProvider<CatalogueExtraPages, CataloguePages> {
  /// Pages plus anciennes du catalogue, chargées quand l’utilisateur atteint
  /// la fin de la liste.
  CatalogueExtraPagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogueExtraPagesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogueExtraPagesHash();

  @$internal
  @override
  CatalogueExtraPages create() => CatalogueExtraPages();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CataloguePages value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CataloguePages>(value),
    );
  }
}

String _$catalogueExtraPagesHash() =>
    r'b4d775562b93f12f67be0358bc65c1d81d9f7085';

/// Pages plus anciennes du catalogue, chargées quand l’utilisateur atteint
/// la fin de la liste.

abstract class _$CatalogueExtraPages extends $Notifier<CataloguePages> {
  CataloguePages build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CataloguePages, CataloguePages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CataloguePages, CataloguePages>,
              CataloguePages,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Tout ce qui est chargé à ce stade : la première page temps réel plus
/// les pages plus anciennes.

@ProviderFor(catalogue)
final catalogueProvider = CatalogueProvider._();

/// Tout ce qui est chargé à ce stade : la première page temps réel plus
/// les pages plus anciennes.

final class CatalogueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Tout ce qui est chargé à ce stade : la première page temps réel plus
  /// les pages plus anciennes.
  CatalogueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogueHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Event>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Event>> create(Ref ref) {
    return catalogue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Event>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Event>>>(value),
    );
  }
}

String _$catalogueHash() => r'c862c70a5cb079599e04bfda52fcc748cda49e58';

/// Un « charger plus » n’a de sens qu’une fois la page temps réel pleine.

@ProviderFor(canLoadMoreEvents)
final canLoadMoreEventsProvider = CanLoadMoreEventsProvider._();

/// Un « charger plus » n’a de sens qu’une fois la page temps réel pleine.

final class CanLoadMoreEventsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Un « charger plus » n’a de sens qu’une fois la page temps réel pleine.
  CanLoadMoreEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canLoadMoreEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canLoadMoreEventsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return canLoadMoreEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$canLoadMoreEventsHash() => r'985c4777bb301e823566c178f8785cb3c02c2be7';

@ProviderFor(organizerEvents)
final organizerEventsProvider = OrganizerEventsFamily._();

final class OrganizerEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  OrganizerEventsProvider._({
    required OrganizerEventsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'organizerEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$organizerEventsHash();

  @override
  String toString() {
    return r'organizerEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Event>> create(Ref ref) {
    final argument = this.argument as String;
    return organizerEvents(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrganizerEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$organizerEventsHash() => r'bed13783098534d560aa6a90713118ab23e817bf';

final class OrganizerEventsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Event>>, String> {
  OrganizerEventsFamily._()
    : super(
        retry: null,
        name: r'organizerEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrganizerEventsProvider call(String organizerId) =>
      OrganizerEventsProvider._(argument: organizerId, from: this);

  @override
  String toString() => r'organizerEventsProvider';
}

/// Événements co-organisés par l’organisateur connecté (F-16).

@ProviderFor(coOrganizedEvents)
final coOrganizedEventsProvider = CoOrganizedEventsFamily._();

/// Événements co-organisés par l’organisateur connecté (F-16).

final class CoOrganizedEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  /// Événements co-organisés par l’organisateur connecté (F-16).
  CoOrganizedEventsProvider._({
    required CoOrganizedEventsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'coOrganizedEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coOrganizedEventsHash();

  @override
  String toString() {
    return r'coOrganizedEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Event>> create(Ref ref) {
    final argument = this.argument as String;
    return coOrganizedEvents(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CoOrganizedEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coOrganizedEventsHash() => r'8c8e3702166901f72b2f350ac173c3b8b439a313';

/// Événements co-organisés par l’organisateur connecté (F-16).

final class CoOrganizedEventsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Event>>, String> {
  CoOrganizedEventsFamily._()
    : super(
        retry: null,
        name: r'coOrganizedEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Événements co-organisés par l’organisateur connecté (F-16).

  CoOrganizedEventsProvider call(String userId) =>
      CoOrganizedEventsProvider._(argument: userId, from: this);

  @override
  String toString() => r'coOrganizedEventsProvider';
}

@ProviderFor(eventById)
final eventByIdProvider = EventByIdFamily._();

final class EventByIdProvider
    extends $FunctionalProvider<AsyncValue<Event?>, Event?, Stream<Event?>>
    with $FutureModifier<Event?>, $StreamProvider<Event?> {
  EventByIdProvider._({
    required EventByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventByIdHash();

  @override
  String toString() {
    return r'eventByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Event?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Event?> create(Ref ref) {
    final argument = this.argument as String;
    return eventById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventByIdHash() => r'df9494a221c57784ab1e8d3c1d1cc20bf7271241';

final class EventByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Event?>, String> {
  EventByIdFamily._()
    : super(
        retry: null,
        name: r'eventByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventByIdProvider call(String eventId) =>
      EventByIdProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventByIdProvider';
}

@ProviderFor(EventSearchQuery)
final eventSearchQueryProvider = EventSearchQueryProvider._();

final class EventSearchQueryProvider
    extends $NotifierProvider<EventSearchQuery, String> {
  EventSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventSearchQueryHash();

  @$internal
  @override
  EventSearchQuery create() => EventSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$eventSearchQueryHash() => r'e82468eb75a84dbbcf102188419328fe4deaf5ef';

abstract class _$EventSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(EventCategoryFilter)
final eventCategoryFilterProvider = EventCategoryFilterProvider._();

final class EventCategoryFilterProvider
    extends $NotifierProvider<EventCategoryFilter, EventCategory?> {
  EventCategoryFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventCategoryFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventCategoryFilterHash();

  @$internal
  @override
  EventCategoryFilter create() => EventCategoryFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventCategory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventCategory?>(value),
    );
  }
}

String _$eventCategoryFilterHash() =>
    r'63621eacd56c9afe9df7f16cb79bfc38943ce04e';

abstract class _$EventCategoryFilter extends $Notifier<EventCategory?> {
  EventCategory? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EventCategory?, EventCategory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventCategory?, EventCategory?>,
              EventCategory?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(EventPeriodFilter)
final eventPeriodFilterProvider = EventPeriodFilterProvider._();

final class EventPeriodFilterProvider
    extends $NotifierProvider<EventPeriodFilter, EventPeriod> {
  EventPeriodFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventPeriodFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventPeriodFilterHash();

  @$internal
  @override
  EventPeriodFilter create() => EventPeriodFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventPeriod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventPeriod>(value),
    );
  }
}

String _$eventPeriodFilterHash() => r'3685212b3df82c832dac14e12db14fc4ae61e6ba';

abstract class _$EventPeriodFilter extends $Notifier<EventPeriod> {
  EventPeriod build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EventPeriod, EventPeriod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventPeriod, EventPeriod>,
              EventPeriod,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(EventSortOrder)
final eventSortOrderProvider = EventSortOrderProvider._();

final class EventSortOrderProvider
    extends $NotifierProvider<EventSortOrder, EventSort> {
  EventSortOrderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventSortOrderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventSortOrderHash();

  @$internal
  @override
  EventSortOrder create() => EventSortOrder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventSort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventSort>(value),
    );
  }
}

String _$eventSortOrderHash() => r'7b946a1d964c5ee5176dadef2b5d30f399870bd3';

abstract class _$EventSortOrder extends $Notifier<EventSort> {
  EventSort build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EventSort, EventSort>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventSort, EventSort>,
              EventSort,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Quand vrai, les événements complets sont masqués. Désactivé par défaut :
/// voir un événement complet est une information utile (cela signale un
/// organisateur populaire).

@ProviderFor(HideSoldOut)
final hideSoldOutProvider = HideSoldOutProvider._();

/// Quand vrai, les événements complets sont masqués. Désactivé par défaut :
/// voir un événement complet est une information utile (cela signale un
/// organisateur populaire).
final class HideSoldOutProvider extends $NotifierProvider<HideSoldOut, bool> {
  /// Quand vrai, les événements complets sont masqués. Désactivé par défaut :
  /// voir un événement complet est une information utile (cela signale un
  /// organisateur populaire).
  HideSoldOutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hideSoldOutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hideSoldOutHash();

  @$internal
  @override
  HideSoldOut create() => HideSoldOut();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hideSoldOutHash() => r'2e567223b0132f834593cf2bde94bb4e58709637';

/// Quand vrai, les événements complets sont masqués. Désactivé par défaut :
/// voir un événement complet est une information utile (cela signale un
/// organisateur populaire).

abstract class _$HideSoldOut extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Nombre de filtres *hors valeur par défaut*, affiché en compteur sur le
/// bouton de filtres pour que l’utilisateur sache toujours pourquoi une
/// liste paraît vide.

@ProviderFor(activeFilterCount)
final activeFilterCountProvider = ActiveFilterCountProvider._();

/// Nombre de filtres *hors valeur par défaut*, affiché en compteur sur le
/// bouton de filtres pour que l’utilisateur sache toujours pourquoi une
/// liste paraît vide.

final class ActiveFilterCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Nombre de filtres *hors valeur par défaut*, affiché en compteur sur le
  /// bouton de filtres pour que l’utilisateur sache toujours pourquoi une
  /// liste paraît vide.
  ActiveFilterCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeFilterCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeFilterCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return activeFilterCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeFilterCountHash() => r'364fd85ff9df89776e6748fc0e002f6f72835f5d';

@ProviderFor(filteredEvents)
final filteredEventsProvider = FilteredEventsProvider._();

final class FilteredEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  FilteredEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredEventsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Event>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Event>> create(Ref ref) {
    return filteredEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Event>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Event>>>(value),
    );
  }
}

String _$filteredEventsHash() => r'd5bb7450d4506a36cec7ce8c525825cf1798666a';

/// Sélection éditoriale : les événements les plus proches ayant encore des
/// places.

@ProviderFor(featuredEvents)
final featuredEventsProvider = FeaturedEventsProvider._();

/// Sélection éditoriale : les événements les plus proches ayant encore des
/// places.

final class FeaturedEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Sélection éditoriale : les événements les plus proches ayant encore des
  /// places.
  FeaturedEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredEventsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Event>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Event>> create(Ref ref) {
    return featuredEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Event>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Event>>>(value),
    );
  }
}

String _$featuredEventsHash() => r'8c70cadcea4ab17770c5e6095111e9bade398ca0';

/// Tout ce qui se passe dans les sept prochains jours.

@ProviderFor(weekEvents)
final weekEventsProvider = WeekEventsProvider._();

/// Tout ce qui se passe dans les sept prochains jours.

final class WeekEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Tout ce qui se passe dans les sept prochains jours.
  WeekEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekEventsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Event>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Event>> create(Ref ref) {
    return weekEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Event>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Event>>>(value),
    );
  }
}

String _$weekEventsHash() => r'2d9a980bf1f0ebe89b9f46042fbd004e50475b59';

/// Rail fondé sur la rareté : les événements remplis à au moins 60 % mais
/// pas complets, du plus rempli au moins rempli. C’est la surface de
/// conversion la plus forte de l’écran d’accueil.

@ProviderFor(trendingEvents)
final trendingEventsProvider = TrendingEventsProvider._();

/// Rail fondé sur la rareté : les événements remplis à au moins 60 % mais
/// pas complets, du plus rempli au moins rempli. C’est la surface de
/// conversion la plus forte de l’écran d’accueil.

final class TrendingEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Rail fondé sur la rareté : les événements remplis à au moins 60 % mais
  /// pas complets, du plus rempli au moins rempli. C’est la surface de
  /// conversion la plus forte de l’écran d’accueil.
  TrendingEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendingEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendingEventsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Event>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Event>> create(Ref ref) {
    return trendingEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Event>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Event>>>(value),
    );
  }
}

String _$trendingEventsHash() => r'6a2c343649e6f9262b702c49ee8098e03af9058c';

/// Le catalogue regroupé par activité, dans l'ordre de l'énumération
/// [EventCategory] — le même que celui du rail de catégories, pour que l'œil
/// retrouve les sections là où il a vu les pastilles.
///
/// Les catégories vides sont omises : une section « Sport — 0 événement »
/// ne sert qu'à dire que le produit est pauvre. Le groupement se fait en une
/// passe sur ce qui est déjà chargé, sans requête Firestore de plus.

@ProviderFor(categorySections)
final categorySectionsProvider = CategorySectionsProvider._();

/// Le catalogue regroupé par activité, dans l'ordre de l'énumération
/// [EventCategory] — le même que celui du rail de catégories, pour que l'œil
/// retrouve les sections là où il a vu les pastilles.
///
/// Les catégories vides sont omises : une section « Sport — 0 événement »
/// ne sert qu'à dire que le produit est pauvre. Le groupement se fait en une
/// passe sur ce qui est déjà chargé, sans requête Firestore de plus.

final class CategorySectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategorySection>>,
          AsyncValue<List<CategorySection>>,
          AsyncValue<List<CategorySection>>
        >
    with $Provider<AsyncValue<List<CategorySection>>> {
  /// Le catalogue regroupé par activité, dans l'ordre de l'énumération
  /// [EventCategory] — le même que celui du rail de catégories, pour que l'œil
  /// retrouve les sections là où il a vu les pastilles.
  ///
  /// Les catégories vides sont omises : une section « Sport — 0 événement »
  /// ne sert qu'à dire que le produit est pauvre. Le groupement se fait en une
  /// passe sur ce qui est déjà chargé, sans requête Firestore de plus.
  CategorySectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categorySectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categorySectionsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<CategorySection>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<CategorySection>> create(Ref ref) {
    return categorySections(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<CategorySection>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<CategorySection>>>(
        value,
      ),
    );
  }
}

String _$categorySectionsHash() => r'47acfc289f782bfe66f3031d766964aacd60b8c8';

/// Le catalogue de l'écran « Tous les événements », pour une [category]
/// donnée (`null` = toutes).
///
/// Il applique les **mêmes** réglages globaux que [filteredEvents] — période,
/// tri, masquage des complets — pour que le menu « Filtres » ait le même
/// effet partout. Deux écarts délibérés :
///  * la catégorie est un paramètre et non le filtre global : ouvrir « Tout
///    voir » sur la section Concert ne doit pas replier l'accueil en mode
///    filtré au retour ;
///  * la requête texte est ignorée : elle appartient à l'onglet Recherche, et
///    un mot tapé là-bas ne doit pas vider silencieusement ce catalogue.
///
/// Contrepartie assumée : le compteur de résultats du menu « Filtres » lit
/// [filteredEvents], et peut donc différer de cette liste quand la catégorie
/// locale n'est pas la catégorie globale.

@ProviderFor(browsableEvents)
final browsableEventsProvider = BrowsableEventsFamily._();

/// Le catalogue de l'écran « Tous les événements », pour une [category]
/// donnée (`null` = toutes).
///
/// Il applique les **mêmes** réglages globaux que [filteredEvents] — période,
/// tri, masquage des complets — pour que le menu « Filtres » ait le même
/// effet partout. Deux écarts délibérés :
///  * la catégorie est un paramètre et non le filtre global : ouvrir « Tout
///    voir » sur la section Concert ne doit pas replier l'accueil en mode
///    filtré au retour ;
///  * la requête texte est ignorée : elle appartient à l'onglet Recherche, et
///    un mot tapé là-bas ne doit pas vider silencieusement ce catalogue.
///
/// Contrepartie assumée : le compteur de résultats du menu « Filtres » lit
/// [filteredEvents], et peut donc différer de cette liste quand la catégorie
/// locale n'est pas la catégorie globale.

final class BrowsableEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Le catalogue de l'écran « Tous les événements », pour une [category]
  /// donnée (`null` = toutes).
  ///
  /// Il applique les **mêmes** réglages globaux que [filteredEvents] — période,
  /// tri, masquage des complets — pour que le menu « Filtres » ait le même
  /// effet partout. Deux écarts délibérés :
  ///  * la catégorie est un paramètre et non le filtre global : ouvrir « Tout
  ///    voir » sur la section Concert ne doit pas replier l'accueil en mode
  ///    filtré au retour ;
  ///  * la requête texte est ignorée : elle appartient à l'onglet Recherche, et
  ///    un mot tapé là-bas ne doit pas vider silencieusement ce catalogue.
  ///
  /// Contrepartie assumée : le compteur de résultats du menu « Filtres » lit
  /// [filteredEvents], et peut donc différer de cette liste quand la catégorie
  /// locale n'est pas la catégorie globale.
  BrowsableEventsProvider._({
    required BrowsableEventsFamily super.from,
    required EventCategory? super.argument,
  }) : super(
         retry: null,
         name: r'browsableEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$browsableEventsHash();

  @override
  String toString() {
    return r'browsableEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Event>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Event>> create(Ref ref) {
    final argument = this.argument as EventCategory?;
    return browsableEvents(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Event>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Event>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BrowsableEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$browsableEventsHash() => r'ab4e7ed41853453326f050b9fc643aacb8a1ca00';

/// Le catalogue de l'écran « Tous les événements », pour une [category]
/// donnée (`null` = toutes).
///
/// Il applique les **mêmes** réglages globaux que [filteredEvents] — période,
/// tri, masquage des complets — pour que le menu « Filtres » ait le même
/// effet partout. Deux écarts délibérés :
///  * la catégorie est un paramètre et non le filtre global : ouvrir « Tout
///    voir » sur la section Concert ne doit pas replier l'accueil en mode
///    filtré au retour ;
///  * la requête texte est ignorée : elle appartient à l'onglet Recherche, et
///    un mot tapé là-bas ne doit pas vider silencieusement ce catalogue.
///
/// Contrepartie assumée : le compteur de résultats du menu « Filtres » lit
/// [filteredEvents], et peut donc différer de cette liste quand la catégorie
/// locale n'est pas la catégorie globale.

final class BrowsableEventsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<Event>>, EventCategory?> {
  BrowsableEventsFamily._()
    : super(
        retry: null,
        name: r'browsableEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le catalogue de l'écran « Tous les événements », pour une [category]
  /// donnée (`null` = toutes).
  ///
  /// Il applique les **mêmes** réglages globaux que [filteredEvents] — période,
  /// tri, masquage des complets — pour que le menu « Filtres » ait le même
  /// effet partout. Deux écarts délibérés :
  ///  * la catégorie est un paramètre et non le filtre global : ouvrir « Tout
  ///    voir » sur la section Concert ne doit pas replier l'accueil en mode
  ///    filtré au retour ;
  ///  * la requête texte est ignorée : elle appartient à l'onglet Recherche, et
  ///    un mot tapé là-bas ne doit pas vider silencieusement ce catalogue.
  ///
  /// Contrepartie assumée : le compteur de résultats du menu « Filtres » lit
  /// [filteredEvents], et peut donc différer de cette liste quand la catégorie
  /// locale n'est pas la catégorie globale.

  BrowsableEventsProvider call(EventCategory? category) =>
      BrowsableEventsProvider._(argument: category, from: this);

  @override
  String toString() => r'browsableEventsProvider';
}
