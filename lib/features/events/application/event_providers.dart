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

/// Taille de page du catalogue, bien en dessous des 200 que les règles
/// autorisent par requête : un listener relit toute sa page après une
/// reconnexion, et les lectures sont le budget du quota gratuit.
const cataloguePageSize = EventRemoteDataSource.maxPageSize;

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return EventRepositoryImpl(
    remote: EventRemoteDataSource(ref.watch(firestoreProvider)),
    clock: ref.watch(clockProvider),
  );
}

/// Première page des événements à venir, en temps réel (ceux du jour
/// restent visibles jusqu’à minuit).
@riverpod
Stream<List<Event>> upcomingEvents(Ref ref) {
  final from = ref.watch(clockProvider)().startOfDay;
  return ref.watch(eventRepositoryProvider).watchUpcoming(from: from);
}

/// Pages plus anciennes du catalogue, chargées quand l’utilisateur atteint
/// la fin de la liste.
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

/// Tout ce qui est chargé à ce stade : la première page temps réel plus
/// les pages plus anciennes.
@riverpod
AsyncValue<List<Event>> catalogue(Ref ref) {
  final older = ref.watch(catalogueExtraPagesProvider).events;
  return ref
      .watch(upcomingEventsProvider)
      .whenData((live) => mergeCatalogue(live, older));
}

/// Un « charger plus » n’a de sens qu’une fois la page temps réel pleine.
@riverpod
bool canLoadMoreEvents(Ref ref) {
  final live = ref.watch(upcomingEventsProvider).value;
  if (live == null || live.length < cataloguePageSize) return false;
  return ref.watch(catalogueExtraPagesProvider).hasMore;
}

@riverpod
Stream<List<Event>> organizerEvents(Ref ref, String organizerId) =>
    ref.watch(eventRepositoryProvider).watchByOrganizer(organizerId);

/// Événements co-organisés par l’organisateur connecté (F-16).
@riverpod
Stream<List<Event>> coOrganizedEvents(Ref ref, String userId) =>
    ref.watch(eventRepositoryProvider).watchCoOrganized(userId);

@riverpod
Stream<Event?> eventById(Ref ref, String eventId) =>
    ref.watch(eventRepositoryProvider).watchById(eventId);

// ---------------------------------------------------------------------------
// Recherche et filtres
//
// Le filtrage se fait côté client sur le catalogue déjà chargé : cela évite
// à la fois un index plein texte et un index composite par combinaison de
// filtres. La couture est délibérée — `filteredEvents` est le seul endroit
// qui sait comment une requête est appliquée, si bien que passer à
// Algolia/Typesense (ou à un filtrage côté serveur) ne touche qu’un
// provider, pas l’interface.
// ---------------------------------------------------------------------------

/// Tris proposés dans la feuille de recherche.
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

/// Fenêtre temporelle grossière. Les utilisateurs pensent en « ce
/// week-end », pas en sélecteur de dates : les fenêtres courantes sont donc
/// à une tape, et le sélecteur n’est que le recours.
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

/// Quand vrai, les événements complets sont masqués. Désactivé par défaut :
/// voir un événement complet est une information utile (cela signale un
/// organisateur populaire).
@riverpod
class HideSoldOut extends _$HideSoldOut {
  @override
  bool build() => false;

  void toggle() => state = !state;
  // ignore: avoid_positional_boolean_parameters
  void set(bool value) => state = value;
}

/// Nombre de filtres *hors valeur par défaut*, affiché en compteur sur le
/// bouton de filtres pour que l’utilisateur sache toujours pourquoi une
/// liste paraît vide.
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

/// Le titre, le lieu, l’organisateur et la catégorie sont tous
/// interrogeables : les utilisateurs tapent « Antananarivo » ou
/// « concert » aussi souvent qu’un titre exact.
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
// Sections de l’accueil
//
// Le fil est éditorialisé plutôt que chronologique : trois rails nommés
// répondent à trois intentions distinctes (« montre-moi le meilleur »,
// « que faire cette semaine », « qu’est-ce qui part vite ») avant de
// retomber sur le catalogue complet.
// ---------------------------------------------------------------------------

/// Sélection éditoriale : les événements les plus proches ayant encore des
/// places.
@riverpod
AsyncValue<List<Event>> featuredEvents(Ref ref) => ref
    .watch(catalogueProvider)
    .whenData((events) => events.where((e) => !e.isFull).take(5).toList());

/// Tout ce qui se passe dans les sept prochains jours.
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

/// Rail fondé sur la rareté : les événements remplis à au moins 60 % mais
/// pas complets, du plus rempli au moins rempli. C’est la surface de
/// conversion la plus forte de l’écran d’accueil.
@riverpod
AsyncValue<List<Event>> trendingEvents(Ref ref) =>
    ref.watch(catalogueProvider).whenData((events) {
      final list = events.where((e) => !e.isFull && e.fillRate >= 0.6).toList()
        ..sort((a, b) => b.fillRate.compareTo(a.fillRate));
      return list.take(10).toList();
    });

// ---------------------------------------------------------------------------
// Parcours par activité et catalogue complet
// ---------------------------------------------------------------------------

/// Une section « activité » de l'accueil : une catégorie et ses événements,
/// dans l'ordre chronologique du catalogue.
class CategorySection {
  const CategorySection({required this.category, required this.events});

  final EventCategory category;
  final List<Event> events;
}

/// Le catalogue regroupé par activité, dans l'ordre de l'énumération
/// [EventCategory] — le même que celui du rail de catégories, pour que l'œil
/// retrouve les sections là où il a vu les pastilles.
///
/// Les catégories vides sont omises : une section « Sport — 0 événement »
/// ne sert qu'à dire que le produit est pauvre. Le groupement se fait en une
/// passe sur ce qui est déjà chargé, sans requête Firestore de plus.
@riverpod
AsyncValue<List<CategorySection>> categorySections(Ref ref) =>
    ref.watch(catalogueProvider).whenData((events) {
      final byCategory = <EventCategory, List<Event>>{};
      for (final event in events) {
        (byCategory[event.category] ??= []).add(event);
      }
      return [
        for (final category in EventCategory.values)
          if (byCategory[category] case final list?)
            CategorySection(
              category: category,
              events: List<Event>.unmodifiable(list),
            ),
      ];
    });

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
@riverpod
AsyncValue<List<Event>> browsableEvents(Ref ref, EventCategory? category) {
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
            .toList()
          ..sort(_comparator(sort));
    return List<Event>.unmodifiable(result);
  });
}
