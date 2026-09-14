import 'package:eventhub/features/events/domain/entities/event.dart';

/// Merges the live first page of the catalogue with older pages loaded on
/// demand.
///
/// The live page wins for any event present in both (it is fresher), the
/// result is deduplicated and in catalogue order (`startsAt`, then id), and
/// an event that moved out of the upcoming window in the live page is not
/// resurrected from a stale older page.
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

/// Older pages of the catalogue.
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
