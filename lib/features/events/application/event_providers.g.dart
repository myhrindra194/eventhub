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

String _$eventRepositoryHash() => r'5b86b33aaf84ca6d926bcd9f5425788019b350fe';

@ProviderFor(imageStorageRepository)
final imageStorageRepositoryProvider = ImageStorageRepositoryProvider._();

final class ImageStorageRepositoryProvider
    extends
        $FunctionalProvider<
          ImageStorageRepository,
          ImageStorageRepository,
          ImageStorageRepository
        >
    with $Provider<ImageStorageRepository> {
  ImageStorageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageStorageRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageStorageRepositoryHash();

  @$internal
  @override
  $ProviderElement<ImageStorageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageStorageRepository create(Ref ref) {
    return imageStorageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageStorageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageStorageRepository>(value),
    );
  }
}

String _$imageStorageRepositoryHash() =>
    r'b1dbd90e949a11870b81bb0eea27e6871a2904af';

/// First page of upcoming events, live (today's events stay visible until
/// midnight).

@ProviderFor(upcomingEvents)
final upcomingEventsProvider = UpcomingEventsProvider._();

/// First page of upcoming events, live (today's events stay visible until
/// midnight).

final class UpcomingEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  /// First page of upcoming events, live (today's events stay visible until
  /// midnight).
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

/// Older catalogue pages, loaded when the user reaches the end of the list.

@ProviderFor(CatalogueExtraPages)
final catalogueExtraPagesProvider = CatalogueExtraPagesProvider._();

/// Older catalogue pages, loaded when the user reaches the end of the list.
final class CatalogueExtraPagesProvider
    extends $NotifierProvider<CatalogueExtraPages, CataloguePages> {
  /// Older catalogue pages, loaded when the user reaches the end of the list.
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

/// Older catalogue pages, loaded when the user reaches the end of the list.

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

/// Everything loaded so far: live first page + older pages.

@ProviderFor(catalogue)
final catalogueProvider = CatalogueProvider._();

/// Everything loaded so far: live first page + older pages.

final class CatalogueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Everything loaded so far: live first page + older pages.
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

/// A "load more" makes sense only once the live page is full.

@ProviderFor(canLoadMoreEvents)
final canLoadMoreEventsProvider = CanLoadMoreEventsProvider._();

/// A "load more" makes sense only once the live page is full.

final class CanLoadMoreEventsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// A "load more" makes sense only once the live page is full.
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

/// Events the signed-in organizer co-organizes (F-16).

@ProviderFor(coOrganizedEvents)
final coOrganizedEventsProvider = CoOrganizedEventsFamily._();

/// Events the signed-in organizer co-organizes (F-16).

final class CoOrganizedEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  /// Events the signed-in organizer co-organizes (F-16).
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

/// Events the signed-in organizer co-organizes (F-16).

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

  /// Events the signed-in organizer co-organizes (F-16).

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

/// When true, sold-out events are hidden. Off by default: seeing a full
/// event is useful information (it signals a popular organizer).

@ProviderFor(HideSoldOut)
final hideSoldOutProvider = HideSoldOutProvider._();

/// When true, sold-out events are hidden. Off by default: seeing a full
/// event is useful information (it signals a popular organizer).
final class HideSoldOutProvider extends $NotifierProvider<HideSoldOut, bool> {
  /// When true, sold-out events are hidden. Off by default: seeing a full
  /// event is useful information (it signals a popular organizer).
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

/// When true, sold-out events are hidden. Off by default: seeing a full
/// event is useful information (it signals a popular organizer).

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

/// Number of *non-default* filters, shown as a counter on the filter button
/// so the user always knows why a list looks empty.

@ProviderFor(activeFilterCount)
final activeFilterCountProvider = ActiveFilterCountProvider._();

/// Number of *non-default* filters, shown as a counter on the filter button
/// so the user always knows why a list looks empty.

final class ActiveFilterCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Number of *non-default* filters, shown as a counter on the filter button
  /// so the user always knows why a list looks empty.
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

/// Editorial selection: the soonest events that still have seats.

@ProviderFor(featuredEvents)
final featuredEventsProvider = FeaturedEventsProvider._();

/// Editorial selection: the soonest events that still have seats.

final class FeaturedEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Editorial selection: the soonest events that still have seats.
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

/// Everything happening in the next seven days.

@ProviderFor(weekEvents)
final weekEventsProvider = WeekEventsProvider._();

/// Everything happening in the next seven days.

final class WeekEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Everything happening in the next seven days.
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

/// Scarcity-driven rail: events at least 60 % full but not sold out, most
/// filled first. It is the strongest conversion surface of the home screen.

@ProviderFor(trendingEvents)
final trendingEventsProvider = TrendingEventsProvider._();

/// Scarcity-driven rail: events at least 60 % full but not sold out, most
/// filled first. It is the strongest conversion surface of the home screen.

final class TrendingEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// Scarcity-driven rail: events at least 60 % full but not sold out, most
  /// filled first. It is the strongest conversion surface of the home screen.
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
