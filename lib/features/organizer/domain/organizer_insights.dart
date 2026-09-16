import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Analytique de l’organisateur, dérivée de données que l’application diffuse
/// déjà.
///
/// Des fonctions pures sur des listes d’`Event` et de `Reservation` : pas
/// d’agrégat Firestore, pas de Cloud Function, aucune lecture supplémentaire.
/// Le prix à payer est une limite connue — tout est calculé à partir d’au plus
/// `maxPageSize` réservations, et une réservation annulée puis reprise ne fait
/// qu’un seul document, si bien que son annulation n’est plus visible. Les
/// deux sont acceptables à l’échelle du MVP, et sont la raison pour laquelle
/// un agrégat côté serveur (`aggregates/`, ROADMAP F-07) existe sur le papier.

/// Ce qui s’est passé, ou ce qui mérite attention.
enum AlertKind {
  /// Quelqu’un a réservé une place.
  booking,

  /// Quelqu’un a rendu sa place.
  cancellation,

  /// Un événement à venir n’a plus une seule place.
  soldOut,

  /// Un événement à venir en est à ses dernières places.
  lastSeats,

  /// Un événement commence d’ici [OrganizerAlerts.startingSoonWindow].
  startingSoon,
}

class OrganizerAlert {
  const OrganizerAlert({
    required this.kind,
    required this.at,
    required this.eventId,
    required this.eventTitle,
    this.personName,
    this.seatsLeft,
  });

  final AlertKind kind;

  /// Quand cela s’est produit — ou, pour une alerte d’état d’événement, quand
  /// l’événement commence.
  final DateTime at;
  final String eventId;
  final String eventTitle;

  /// Renseigné sur [AlertKind.booking] et [AlertKind.cancellation].
  final String? personName;

  /// Renseigné sur les alertes d’état d’événement.
  final int? seatsLeft;
}

abstract final class OrganizerAlerts {
  /// Le même seuil que l’état « dernières places » de la fiche d’événement.
  static const lastSeatsThreshold = 3;
  static const startingSoonWindow = Duration(hours: 24);

  /// Les événements à venir qui méritent un coup d’œil, le plus proche
  /// d’abord. Un événement peut apparaître deux fois (il commence bientôt *et*
  /// il est presque plein) : ce sont deux raisons différentes de l’ouvrir.
  static List<OrganizerAlert> watchlist({
    required List<Event> events,
    required DateTime now,
  }) {
    final upcoming = events.where((e) => !e.hasStarted(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    OrganizerAlert about(Event e, AlertKind kind) => OrganizerAlert(
      kind: kind,
      at: e.startsAt,
      eventId: e.id,
      eventTitle: e.title,
      seatsLeft: e.availablePlaces,
    );

    return [
      for (final e in upcoming) ...[
        if (e.startsAt.difference(now) <= startingSoonWindow)
          about(e, AlertKind.startingSoon),
        if (e.isFull)
          about(e, AlertKind.soldOut)
        else if (e.availablePlaces <= lastSeatsThreshold)
          about(e, AlertKind.lastSeats),
      ],
    ];
  }

  /// Réservations et annulations, les plus récentes d’abord. Une réservation
  /// annulée produit les deux entrées — la réservation a bien eu lieu.
  static List<OrganizerAlert> activity({
    required List<Reservation> reservations,
    int limit = 60,
  }) {
    final items = <OrganizerAlert>[
      for (final r in reservations) ...[
        OrganizerAlert(
          kind: AlertKind.booking,
          at: r.reservedAt,
          eventId: r.eventId,
          eventTitle: r.eventTitle,
          personName: r.userName,
        ),
        if (r.isCancelled && r.cancelledAt != null)
          OrganizerAlert(
            kind: AlertKind.cancellation,
            at: r.cancelledAt!,
            eventId: r.eventId,
            eventTitle: r.eventTitle,
            personName: r.userName,
          ),
      ],
    ]..sort((a, b) => b.at.compareTo(a.at));
    return List.unmodifiable(items.take(limit));
  }
}

class EventPerformance {
  const EventPerformance({required this.event, required this.cancellations});

  final Event event;
  final int cancellations;
}

class OrganizerStats {
  const OrganizerStats({
    required this.eventCount,
    required this.upcomingCount,
    required this.soldOutCount,
    required this.booked,
    required this.capacity,
    required this.cancellations,
    required this.dailyBookings,
    required this.ranking,
    this.revenue = const {},
  });

  /// Calcule les statistiques à [now].
  ///
  /// Les nombres de places viennent des événements (`capacity -
  /// availablePlaces`, la source de vérité transactionnelle) ; la chronologie
  /// et les annulations viennent des documents de réservation.
  factory OrganizerStats.compute({
    required List<Event> events,
    required List<Reservation> reservations,
    required DateTime now,
  }) {
    final daily = List<int>.filled(window, 0);
    final cancelledByEvent = <String, int>{};
    var cancellations = 0;
    final today = _dayNumber(now);

    for (final r in reservations) {
      if (r.isCancelled) {
        cancellations++;
        cancelledByEvent.update(r.eventId, (v) => v + 1, ifAbsent: () => 1);
      }
      final offset = today - _dayNumber(r.reservedAt);
      if (offset >= 0 && offset < window) daily[window - 1 - offset]++;
    }

    // L’argent réellement encaissé, par devise : uniquement les billets
    // payants actifs — un billet remboursé est annulé et ne compte pas.
    final revenue = <String, int>{};
    for (final r in reservations.where((r) => r.isActive && r.isPaid)) {
      revenue.update(
        r.currency ?? 'EUR',
        (v) => v + r.pricePaid,
        ifAbsent: () => r.pricePaid,
      );
    }

    final upcoming = events.where((e) => !e.hasStarted(now)).toList();
    final ranking = [
      for (final e in upcoming)
        EventPerformance(event: e, cancellations: cancelledByEvent[e.id] ?? 0),
    ]..sort((a, b) => b.event.fillRate.compareTo(a.event.fillRate));

    return OrganizerStats(
      eventCount: events.length,
      upcomingCount: upcoming.length,
      soldOutCount: upcoming.where((e) => e.isFull).length,
      booked: events.fold(0, (sum, e) => sum + e.reservedCount),
      capacity: events.fold(0, (sum, e) => sum + e.capacity),
      cancellations: cancellations,
      dailyBookings: List.unmodifiable(daily),
      ranking: List.unmodifiable(ranking),
      revenue: Map.unmodifiable(revenue),
    );
  }

  /// Longueur de [dailyBookings], en jours.
  static const window = 14;

  final int eventCount;
  final int upcomingCount;
  final int soldOutCount;

  /// Places prises, tous événements confondus.
  final int booked;
  final int capacity;
  final int cancellations;

  /// Réservations par jour calendaire, la plus ancienne d’abord ; la dernière
  /// entrée, c’est aujourd’hui.
  final List<int> dailyBookings;

  /// Les événements à venir, les plus remplis d’abord.
  final List<EventPerformance> ranking;

  /// Montant encaissé par code devise, en unités mineures (F-11).
  final Map<String, int> revenue;

  double get fillRate => capacity == 0 ? 0 : booked / capacity;

  double get cancellationRate {
    final total = booked + cancellations;
    return total == 0 ? 0 : cancellations / total;
  }

  int get bookingsLast7Days =>
      dailyBookings.skip(window - 7).fold(0, (sum, v) => sum + v);

  /// Numéro de jour calendaire, insensible aux changements d’heure (un
  /// `difference().inDays` local à cheval sur un passage heure d’été / heure
  /// d’hiver est faux d’un jour).
  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
