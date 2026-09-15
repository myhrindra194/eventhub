import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';

/// `events/{id}` as a booking or a cancellation reads it inside its
/// transaction.
///
/// Why not the events feature's DTO: the reservation must copy
/// `title`, `startsAt`, `location` and `organizerId` *exactly* — the rules
/// compare them with `==` to the event (`matchesEvent()`). A round trip
/// through [DateTime] loses the nanoseconds of a Firestore `Timestamp` and
/// would get every booking refused, so the raw values are kept next to the
/// parsed [event] the domain policy needs.
class BookingEvent {
  BookingEvent(this.id, this.raw);

  final String id;
  final Map<String, dynamic> raw;

  /// The fields a reservation copies, untouched.
  Map<String, Object?> get copiedFields => {
    'organizerId': raw['organizerId'],
    'eventTitle': raw['title'],
    'eventStartsAt': raw['startsAt'],
    'eventLocation': raw['location'],
  };

  int get availablePlaces => _int(raw['availablePlaces']);

  /// Whom booking and cancellation notices go to: the owner and every
  /// co-organizer, once each.
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
