import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/events/application/catalogue.dart';
import 'package:eventhub/features/events/data/datasources/event_remote_data_source.dart';
import 'package:eventhub/features/events/data/repositories/event_repository_impl.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/repositories/event_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'event_providers.g.dart';

/// Page size of the catalogue, well under the 200 the rules allow per query:
/// a listener re-reads its whole page after a reconnection, and reads are
/// the free quota's budget.
const cataloguePageSize = EventRemoteDataSource.maxPageSize;

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return EventRepositoryImpl(
    remote: EventRemoteDataSource(ref.watch(firestoreProvider)),
    clock: ref.watch(clockProvider),
  );
}

/// First page of upcoming events, live (today's events stay visible until
/// midnight).
@riverpod
Stream<List<Event>> upcomingEvents(Ref ref) {
  final from = ref.watch(clockProvider)().startOfDay;
  return ref.watch(eventRepositoryProvider).watchUpcoming(from: from);
}

/// Older catalogue pages, loaded when the user reaches the end of the list.
@Riverpod(keepAlive: true)
class CatalogueExtraPages extends _$CatalogueExtraPages {
  @override
  CataloguePages build() => const CataloguePages();

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final loaded = ref.read(catalogueProvider).value ?? const <Event>[];
    if (loaded.isEmpty) return;

    state = state.copyWith(loading: true);
    final result = await ref
        .read(eventRepositoryProvider)
        .fetchUpcomingAfter(
          from: ref.read(clockProvider)().startOfDay,
          after: loaded.last,
          limit: cataloguePageSize,
        );
    state = switch (result) {
      Ok(:final value) => CataloguePages(
        events: [...state.events, ...value],
        hasMore: value.length == cataloguePageSize,
      ),
      Err() => state.copyWith(loading: false),
    };
  }
}

/// Everything loaded so far: live first page + older pages.
@riverpod
AsyncValue<List<Event>> catalogue(Ref ref) {
  final older = ref.watch(catalogueExtraPagesProvider).events;
  return ref
      .watch(upcomingEventsProvider)
      .whenData((live) => mergeCatalogue(live, older));
}

/// A "load more" makes sense only once the live page is full.
@riverpod
bool canLoadMoreEvents(Ref ref) {
  final live = ref.watch(upcomingEventsProvider).value;
  if (live == null || live.length < cataloguePageSize) return false;
  return ref.watch(catalogueExtraPagesProvider).hasMore;
}

@riverpod
Stream<List<Event>> organizerEvents(Ref ref, String organizerId) =>
    ref.watch(eventRepositoryProvider).watchByOrganizer(organizerId);

/// Events the signed-in organizer co-organizes (F-16).
@riverpod
Stream<List<Event>> coOrganizedEvents(Ref ref, String userId) =>
    ref.watch(eventRepositoryProvider).watchCoOrganized(userId);

@riverpod
Stream<Event?> eventById(Ref ref, String eventId) =>
    ref.watch(eventRepositoryProvider).watchById(eventId);

// ---------------------------------------------------------------------------
// Search & filter
//
// Filtering is done client-side over the loaded catalogue: it avoids both a
// full-text index and a composite index per filter combination. The seam is
// deliberate — `filteredEvents` is the only place that knows how a query is
// applied, so switching to Algolia/Typesense (or to server-side filtering)
// touches one provider, not the UI.
// ---------------------------------------------------------------------------

/// Ordering offered in the search sheet.
enum EventSort {
  dateAsc,
  dateDesc,
  availability,
  alphabetical;

  String get label => switch (this) {
    EventSort.dateAsc => 'Date (au plus tôt)',
    EventSort.dateDesc => 'Date (au plus tard)',
    EventSort.availability => 'Places disponibles',
    EventSort.alphabetical => 'Ordre alphabétique',
  };
}

/// Coarse time window. Users think in "ce week-end", not in date pickers,
/// so the common windows are one tap away and the picker is the fallback.
enum EventPeriod {
  any,
  today,
  week,
  month;

  String get label => switch (this) {
    EventPeriod.any => 'Peu importe',
    EventPeriod.today => "Aujourd'hui",
    EventPeriod.week => 'Cette semaine',
    EventPeriod.month => 'Ce mois-ci',
  };

  bool matches(DateTime date, DateTime now) => switch (this) {
    EventPeriod.any => true,
    EventPeriod.today =>
      date.year == now.year && date.month == now.month && date.day == now.day,
    EventPeriod.week => date.isBefore(now.add(const Duration(days: 7))),
    EventPeriod.month => date.isBefore(now.add(const Duration(days: 31))),
  };
}

@riverpod
class EventSearchQuery extends _$EventSearchQuery {
  @override
  String build() => '';

  void set(String query) => state = query;
  void clear() => state = '';
}

@riverpod
class EventCategoryFilter extends _$EventCategoryFilter {
  @override
  EventCategory? build() => null;

  void select(EventCategory? category) => state = category;

  void toggle(EventCategory category) =>
      state = state == category ? null : category;
}

@riverpod
class EventPeriodFilter extends _$EventPeriodFilter {
  @override
  EventPeriod build() => EventPeriod.any;

  void select(EventPeriod period) => state = period;
}

@riverpod
class EventSortOrder extends _$EventSortOrder {
  @override
  EventSort build() => EventSort.dateAsc;

  void select(EventSort sort) => state = sort;
}

/// When true, sold-out events are hidden. Off by default: seeing a full
/// event is useful information (it signals a popular organizer).
@riverpod
class HideSoldOut extends _$HideSoldOut {
  @override
  bool build() => false;

  void toggle() => state = !state;
  // ignore: avoid_positional_boolean_parameters
  void set(bool value) => state = value;
}

/// Number of *non-default* filters, shown as a counter on the filter button
/// so the user always knows why a list looks empty.
@riverpod
int activeFilterCount(Ref ref) {
  var count = 0;
  if (ref.watch(eventCategoryFilterProvider) != null) count++;
  if (ref.watch(eventPeriodFilterProvider) != EventPeriod.any) count++;
  if (ref.watch(hideSoldOutProvider)) count++;
  if (ref.watch(eventSortOrderProvider) != EventSort.dateAsc) count++;
  return count;
}

@riverpod
AsyncValue<List<Event>> filteredEvents(Ref ref) {
  final query = ref.watch(eventSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(eventCategoryFilterProvider);
  final period = ref.watch(eventPeriodFilterProvider);
  final sort = ref.watch(eventSortOrderProvider);
  final hideSoldOut = ref.watch(hideSoldOutProvider);
  final now = ref.watch(clockProvider)();

  return ref.watch(catalogueProvider).whenData((events) {
    final result =
        events
            .where((e) => category == null || e.category == category)
            .where((e) => period.matches(e.startsAt, now))
            .where((e) => !hideSoldOut || !e.isFull)
            .where((e) => query.isEmpty || _matchesQuery(e, query))
            .toList()
          ..sort(_comparator(sort));
    return List<Event>.unmodifiable(result);
  });
}

/// Title, location, organizer and category are all searchable: users type
/// "Antananarivo" or "concert" as often as an exact title.
bool _matchesQuery(Event event, String query) =>
    event.title.toLowerCase().contains(query) ||
    event.location.toLowerCase().contains(query) ||
    event.organizerName.toLowerCase().contains(query) ||
    event.category.label.toLowerCase().contains(query);

int Function(Event, Event) _comparator(EventSort sort) => switch (sort) {
  EventSort.dateAsc => (a, b) => a.startsAt.compareTo(b.startsAt),
  EventSort.dateDesc => (a, b) => b.startsAt.compareTo(a.startsAt),
  EventSort.availability => (a, b) => b.availablePlaces.compareTo(
    a.availablePlaces,
  ),
  EventSort.alphabetical => (a, b) => a.title.toLowerCase().compareTo(
    b.title.toLowerCase(),
  ),
};

// ---------------------------------------------------------------------------
// Home sections
//
// The feed is curated rather than chronological: three named rails answer
// three different intents ("montre-moi le meilleur", "que faire cette
// semaine", "qu'est-ce qui part vite") before falling back to the full
// catalogue.
// ---------------------------------------------------------------------------

/// Editorial selection: the soonest events that still have seats.
@riverpod
AsyncValue<List<Event>> featuredEvents(Ref ref) => ref
    .watch(catalogueProvider)
    .whenData((events) => events.where((e) => !e.isFull).take(5).toList());

/// Everything happening in the next seven days.
@riverpod
AsyncValue<List<Event>> weekEvents(Ref ref) {
  final now = ref.watch(clockProvider)();
  final limit = now.add(const Duration(days: 7));
  return ref
      .watch(catalogueProvider)
      .whenData(
        (events) => events.where((e) => e.startsAt.isBefore(limit)).toList(),
      );
}

/// Scarcity-driven rail: events at least 60 % full but not sold out, most
/// filled first. It is the strongest conversion surface of the home screen.
@riverpod
AsyncValue<List<Event>> trendingEvents(Ref ref) =>
    ref.watch(catalogueProvider).whenData((events) {
      final list = events.where((e) => !e.isFull && e.fillRate >= 0.6).toList()
        ..sort((a, b) => b.fillRate.compareTo(a.fillRate));
      return list.take(10).toList();
    });
