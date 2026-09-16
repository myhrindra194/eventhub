import 'dart:math' as math;

import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';

/// Événement publié.
///
/// Le cahier des charges liste `date` et `time` séparément ; ils sont
/// stockés ici en un unique instant [startsAt], pour que le tri, les
/// requêtes « à venir » et la règle « déjà commencé » soient exacts.
/// [date] et [time] subsistent comme vues.
@freezed
abstract class Event with _$Event {
  const Event._();

  const factory Event({
    required String id,
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startsAt,
    required String location,
    required int capacity,
    required int availablePlaces,
    required String organizerId,
    required String organizerName,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,

    /// Co-organisateurs (F-16) : les organisateurs ayant accepté une
    /// invitation. Ils gèrent le contenu, la liste des participants et
    /// l’accueil ; seul le propriétaire ([organizerId]) compose l’équipe
    /// et peut supprimer l’événement.
    @Default(<String>[]) List<String> staffIds,

    /// Types de billets (F-12), dans l’ordre d’affichage. Vide pour un
    /// événement simple, doté d’un unique pool gratuit de [capacity]
    /// places.
    @Default(<EventTier>[]) List<EventTier> tiers,

    /// Code ISO de la devise des types payants (`EUR`, `USD`, `MGA`).
    String? currency,
  }) = _Event;

  DateTime get date => DateTime(startsAt.year, startsAt.month, startsAt.day);
  TimeOfDayValue get time =>
      TimeOfDayValue(hour: startsAt.hour, minute: startsAt.minute);

  int get reservedCount => capacity - availablePlaces;
  bool get isFull => availablePlaces <= 0;
  double get fillRate => capacity == 0 ? 0 : reservedCount / capacity;

  bool hasStarted(DateTime now) => !startsAt.isAfter(now);
  bool isOwnedBy(String userId) => organizerId == userId;
  bool isStaff(String userId) => staffIds.contains(userId);

  /// Propriétaire ou co-organisateur.
  bool isManagedBy(String userId) => isOwnedBy(userId) || isStaff(userId);

  bool get hasTiers => tiers.isNotEmpty;

  /// Participation gratuite : aucun type de billet, ou uniquement des
  /// types gratuits.
  bool get isFree => tiers.every((t) => t.isFree);

  /// Billet payant le moins cher, `null` quand rien n’est payant.
  int? get minPrice {
    final paid = tiers.where((t) => !t.isFree).map((t) => t.price);
    return paid.isEmpty ? null : paid.reduce(math.min);
  }

  bool get hasFreeTier => !hasTiers || tiers.any((t) => t.isFree);

  String get currencyCode => currency ?? 'EUR';

  EventTier? tier(String id) {
    for (final t in tiers) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Valeur d’heure sans dépendance à Flutter, pour que le domaine reste
/// agnostique du framework.
@freezed
abstract class TimeOfDayValue with _$TimeOfDayValue {
  const factory TimeOfDayValue({required int hour, required int minute}) =
      _TimeOfDayValue;
}
