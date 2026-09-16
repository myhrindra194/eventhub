import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_dto.freezed.dart';
part 'event_dto.g.dart';

/// Fonction de premier niveau plutôt que statique : freezed recopie
/// l’annotation `@JsonKey` dans le fichier généré, où un simple nom de
/// membre statique ne se résout pas.
List<EventTierDto> _tiersFromJson(Object? json) => EventDto.tiersFromMap(json);

List<String> _staffIdsFromJson(Object? json) => [
  if (json is List)
    for (final id in json)
      if (id is String && id.isNotEmpty) id,
];

/// Document `events/{eventId}`.
///
/// Un seul document porte tout l’événement — types de billets compris, sous
/// forme de map `{tierId: {name, description, price, capacity, available,
/// order}}` — de sorte qu’un unique listener de snapshot suffit à afficher
/// une carte, et qu’une réservation déplace le compteur de l’événement et
/// celui de son type dans la même écriture (les règles comparent les deux).
/// Une map plutôt qu’une liste, parce que les règles adressent un type par
/// sa clé (`tiers[tierId].available`) et qu’une liste ne se compare pas
/// ainsi.
///
/// L’id du document n’est pas un champ : [EventDto.fromFirestore] l’injecte.
@freezed
abstract class EventDto with _$EventDto {
  const EventDto._();

  const factory EventDto({
    required String id,
    required String title,
    required String description,
    @JsonKey(unknownEnumValue: EventCategory.other)
    required EventCategory category,
    @TimestampConverter() required DateTime startsAt,
    required String location,

    /// Avec des types de billets, les deux compteurs sont la somme de ceux
    /// des types : le client les calcule dans l’écriture et les règles en
    /// vérifient l’arithmétique.
    required int capacity,
    required int availablePlaces,
    required String organizerId,
    required String organizerName,
    String? imageUrl,

    /// Écrits avec `serverTimestamp()` : `null` dans un snapshot local en
    /// attente.
    @NullableTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,

    /// `EUR`, `USD` ou `MGA` ; null tant qu’aucun type n’est payant.
    String? currency,
    @JsonKey(fromJson: _tiersFromJson)
    @Default(<EventTierDto>[])
    List<EventTierDto> tiers,
    @JsonKey(fromJson: _staffIdsFromJson)
    @Default(<String>[])
    List<String> staffIds,
  }) = _EventDto;

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  /// L’id l’emporte sur toute clé `id` que porterait un document écrit à la
  /// main.
  factory EventDto.fromFirestore(String id, Map<String, dynamic> data) =>
      EventDto.fromJson({...data, 'id': id});

  Event toDomain() => Event(
    id: id,
    title: title,
    description: description,
    category: category,
    startsAt: startsAt,
    location: location,
    capacity: capacity,
    availablePlaces: availablePlaces,
    organizerId: organizerId,
    organizerName: organizerName,
    imageUrl: imageUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
    staffIds: staffIds,
    tiers: [for (final tier in tiers) tier.toDomain()],
    currency: currency,
  );

  /// `{tierId: {...}}` → les types dans l’ordre d’affichage : `order`, puis
  /// l’id pour que des `order` égaux (document édité à la main) restent
  /// stables. Une entrée malformée est ignorée plutôt que de faire échouer
  /// tout l’événement.
  static List<EventTierDto> tiersFromMap(Object? json) {
    if (json is! Map) return const [];
    final tiers =
        <EventTierDto>[
          for (final MapEntry(:key, :value) in json.entries)
            if (key is String && value is Map)
              if (EventTierDto.tryParse(key, Map<String, dynamic>.from(value))
                  case final tier?)
                tier,
        ]..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });
    return tiers;
  }

  /// Les types → la map stockée sur l’événement. `order` est réécrit depuis
  /// la position dans la liste, pour que l’ordre d’affichage soit
  /// exactement celui du formulaire.
  static Map<String, Map<String, Object>> tiersToMap(List<EventTier> tiers) => {
    for (var i = 0; i < tiers.length; i++)
      tiers[i].id: {
        'name': tiers[i].name,
        'description': tiers[i].description,
        'price': tiers[i].price,
        'capacity': tiers[i].capacity,
        'available': tiers[i].available,
        'order': i,
      },
  };

  /// Les champs de contenu que l’organisateur maîtrise, partagés par la
  /// création et la modification.
  ///
  /// [draft] doit être validé (chaînes nettoyées, capacité sommée). Les
  /// compteurs et les types viennent du plan calculé face au document
  /// courant, jamais du brouillon : les règles exigent
  /// `availablePlaces == capacity − taken`. `imageUrl` et `currency` sont
  /// écrits même à null, pour que les vider dans le formulaire les vide
  /// aussi dans le document.
  static Map<String, Object?> contentFields(
    EventDraft draft, {
    required int capacity,
    required int availablePlaces,
    required List<EventTier> tiers,
  }) => {
    'title': draft.title,
    'description': draft.description,
    'category': draft.category.name,
    'startsAt': Timestamp.fromDate(draft.startsAt),
    'location': draft.location,
    'capacity': capacity,
    'availablePlaces': availablePlaces,
    'imageUrl': draft.imageUrl,
    'currency': draft.currency,
    'tiers': tiersToMap(tiers),
  };

  /// Un nouveau document : la seule forme qu’`allow create` accepte —
  /// toutes les places libres, pas encore d’équipe, et le nom de
  /// l’organisateur recopié depuis `users/{uid}.name`.
  static Map<String, Object?> createFields(
    EventDraft draft, {
    required String organizerId,
    required String organizerName,
    required TierPlan? plan,
  }) => {
    ...contentFields(
      draft,
      capacity: plan?.capacity ?? draft.capacity,
      availablePlaces: plan?.available ?? draft.capacity,
      tiers: plan?.tiers ?? const [],
    ),
    'organizerId': organizerId,
    'organizerName': organizerName,
    'staffIds': const <String>[],
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// Une entrée de `events/{id}.tiers`, indexée par [id].
@freezed
abstract class EventTierDto with _$EventTierDto {
  const EventTierDto._();

  const factory EventTierDto({
    required String id,
    required String name,
    required int capacity,
    required int available,

    /// Ce que le type inclut (« Accès backstage »), éventuellement vide.
    @Default('') String description,

    /// Unités mineures entières (centimes ; ariary pour MGA).
    @Default(0) int price,

    /// 0..5, l’ordre d’affichage choisi dans le formulaire.
    @Default(0) int order,
  }) = _EventTierDto;

  factory EventTierDto.fromJson(Map<String, dynamic> json) =>
      _$EventTierDtoFromJson(json);

  /// `null` quand l’entrée n’a pas un champ obligatoire, ou qu’un champ a
  /// le mauvais type.
  static EventTierDto? tryParse(String id, Map<String, dynamic> data) {
    try {
      return EventTierDto.fromJson({...data, 'id': id});
    } on Object {
      return null;
    }
  }

  EventTier toDomain() => EventTier(
    id: id,
    name: name,
    description: description,
    capacity: capacity,
    available: available,
    price: price,
    order: order,
  );
}
