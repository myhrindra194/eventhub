import 'package:eventhub/features/events/domain/entities/event.dart';

/// Fusionne la première page du catalogue, suivie en temps réel, avec les
/// pages plus anciennes chargées à la demande.
///
/// La page temps réel l’emporte pour tout événement présent dans les deux
/// (elle est plus fraîche), le résultat est dédoublonné et dans l’ordre du
/// catalogue (`startsAt`, puis id), et un événement sorti de la fenêtre
/// « à venir » dans la page temps réel n’est pas ressuscité par une page
/// ancienne périmée.
List<Event> mergeCatalogue(List<Event> live, List<Event> older) {
  final byId = <String, Event>{for (final e in older) e.id: e};
  for (final e in live) {
    byId[e.id] = e;
  }
  final merged = byId.values.toList()
    ..sort((a, b) {
      final byDate = a.startsAt.compareTo(b.startsAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
  return List.unmodifiable(merged);
}

/// Pages plus anciennes du catalogue.
class CataloguePages {
  const CataloguePages({
    this.events = const [],
    this.hasMore = true,
    this.loading = false,
  });

  final List<Event> events;
  final bool hasMore;
  final bool loading;

  CataloguePages copyWith({
    List<Event>? events,
    bool? hasMore,
    bool? loading,
  }) => CataloguePages(
    events: events ?? this.events,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
  );
}
