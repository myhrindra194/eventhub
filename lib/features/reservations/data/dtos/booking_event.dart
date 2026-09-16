import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';

/// `events/{id}` tel qu’une réservation ou une annulation le lit à
/// l’intérieur de sa transaction.
///
/// Pourquoi pas le DTO de la feature events : la réservation doit copier
/// `title`, `startsAt`, `location` et `organizerId` *à l’identique* — les
/// règles les comparent à l’événement avec `==` (`matchesEvent()`). Un
/// aller-retour par [DateTime] perd les nanosecondes d’un `Timestamp`
/// Firestore et ferait refuser toutes les réservations : on conserve donc
/// les valeurs brutes à côté de l’[event] parsé dont la policy du domaine
/// a besoin.
class BookingEvent {
  BookingEvent(this.id, this.raw);

  final String id;
  final Map<String, dynamic> raw;

  /// Les champs qu’une réservation copie, sans y toucher.
  Map<String, Object?> get copiedFields => {
    'organizerId': raw['organizerId'],
    'eventTitle': raw['title'],
    'eventStartsAt': raw['startsAt'],
    'eventLocation': raw['location'],
  };

  int get availablePlaces => _int(raw['availablePlaces']);

  /// Les destinataires des notifications de réservation et d’annulation :
  /// le propriétaire et chaque co-organisateur, une seule fois chacun.
  List<String> get teamIds => {
    event.organizerId,
    ...event.staffIds,
  }.where((id) => id.isNotEmpty).toList(growable: false);

  late final Event event = Event(
    id: id,
    title: raw['title'] as String? ?? '',
    description: raw['description'] as String? ?? '',
    category:
        EventCategory.values.asNameMap()[raw['category']] ??
        EventCategory.other,
    startsAt: const TimestampConverter().fromJson(raw['startsAt'] as Object),
    location: raw['location'] as String? ?? '',
    capacity: _int(raw['capacity']),
    availablePlaces: availablePlaces,
    organizerId: raw['organizerId'] as String? ?? '',
    organizerName: raw['organizerName'] as String? ?? '',
    staffIds: [
      for (final id in raw['staffIds'] as List<dynamic>? ?? const [])
        if (id is String) id,
    ],
    tiers: _tiers(raw['tiers']),
    currency: raw['currency'] as String?,
  );

  static List<EventTier> _tiers(Object? value) {
    if (value is! Map) return const [];
    final tiers = [
      for (final MapEntry(:key, :value) in value.entries)
        if (key is String && value is Map)
          EventTier(
            id: key,
            name: value['name'] as String? ?? '',
            description: value['description'] as String? ?? '',
            price: _int(value['price']),
            capacity: _int(value['capacity']),
            available: _int(value['available']),
            order: _int(value['order']),
          ),
    ]..sort((a, b) => a.order.compareTo(b.order));
    return tiers;
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;
}
