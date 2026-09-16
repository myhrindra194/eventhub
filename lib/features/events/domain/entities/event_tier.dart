import 'dart:math' as math;

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_tier.freezed.dart';

/// Un type de billet d’un événement (F-12) : « Standard », « Étudiant »,
/// « VIP »…
///
/// C’est une entrée de la map `tiers` de `events/{id}`, indexée par [id] ;
/// une réservation décrémente le type et l’événement dans la même
/// transaction Firestore, et les règles de sécurité vérifient que les deux
/// ont bougé d’une unité.
/// [price] est exprimé dans l’unité mineure de la devise (voir `Money`) ;
/// 0 signifie gratuit.
@freezed
abstract class EventTier with _$EventTier {
  const EventTier._();

  const factory EventTier({
    required String id,
    required String name,
    required int capacity,
    required int available,
    @Default('') String description,
    @Default(0) int price,
    @Default(0) int order,
  }) = _EventTier;

  static const maxTiers = 6;
  static const maxNameLength = 40;
  static const maxDescriptionLength = 160;

  bool get isFree => price <= 0;
  bool get isSoldOut => available <= 0;
  int get sold => capacity - available;

  /// Forme des identifiants que [TierPlanner] attribue à un nouveau type.
  /// L’id est définitif : c’est la clé de map que les réservations
  /// désignent (`tierId`).
  static bool isValidId(String id) => RegExp(r'^[a-z0-9]{1,20}$').hasMatch(id);
}

/// Un type de billet tel que saisi dans le formulaire d’événement. [id]
/// vaut null pour un nouveau type.
@freezed
abstract class EventTierDraft with _$EventTierDraft {
  const factory EventTierDraft({
    required String name,
    required int capacity,
    String? id,
    @Default('') String description,
    @Default(0) int price,
  }) = _EventTierDraft;

  factory EventTierDraft.fromTier(EventTier tier) => EventTierDraft(
    id: tier.id,
    name: tier.name,
    description: tier.description,
    price: tier.price,
    capacity: tier.capacity,
  );
}

/// Types de billets prêts à être écrits, avec les totaux qu’ils impliquent
/// pour l’événement.
class TierPlan {
  const TierPlan({
    required this.tiers,
    required this.capacity,
    required this.available,
  });

  final List<EventTier> tiers;
  final int capacity;
  final int available;

  bool get hasPaid => tiers.any((t) => !t.isFree);
}

/// Transforme la saisie du formulaire en types de billets, en préservant
/// chaque place déjà vendue. Pure : le formulaire s’en sert pour un retour
/// immédiat, et le dépôt d’événements la rejoue dans la transaction de
/// modification, sur le document tel qu’il y est lu ; les règles de
/// sécurité vérifient ensuite `availablePlaces = capacity − taken`.
abstract final class TierPlanner {
  static String newId([math.Random? random]) {
    final r = random ?? math.Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return 't${List.generate(7, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  /// Un nouvel événement : toutes les places de tous les types sont libres.
  static TierPlan initial(
    List<EventTierDraft> drafts, {
    String Function()? ids,
  }) {
    final tiers = [
      for (var i = 0; i < drafts.length; i++)
        EventTier(
          id: drafts[i].id ?? (ids ?? newId)(),
          name: drafts[i].name,
          description: drafts[i].description,
          price: drafts[i].price,
          capacity: drafts[i].capacity,
          available: drafts[i].capacity,
          order: i,
        ),
    ];
    final capacity = tiers.fold(0, (sum, t) => sum + t.capacity);
    return TierPlan(tiers: tiers, capacity: capacity, available: capacity);
  }

  /// Une modification. `null` signifie que l’événement reste (ou devient)
  /// un événement simple, sans types de billets.
  ///
  /// * un type ne peut pas descendre sous ce qu’il a déjà vendu, ni être
  ///   retiré dès lors qu’il a vendu quoi que ce soit ;
  /// * on ne peut ni ajouter ni retirer des types sur un événement qui a
  ///   déjà des réservations dans l’autre mode — ces réservations ne
  ///   sauraient pas à quel compteur rendre leur place.
  static Result<TierPlan?> apply({
    required int soldWithoutTiers,
    required List<EventTier> current,
    required List<EventTierDraft> drafts,
    String Function()? ids,
  }) {
    final soldInTiers = current.fold(0, (sum, t) => sum + t.sold);
    if (drafts.isEmpty) {
      if (current.isNotEmpty && soldInTiers > 0) {
        return const Err(
          BusinessRuleFailure(
            rule: BusinessRule.tiersLocked,
            message:
                'Des billets ont déjà été vendus par type : les types de '
                'billets ne peuvent plus être retirés.',
          ),
        );
      }
      return const Ok(null);
    }
    if (current.isEmpty && soldWithoutTiers > 0) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.tiersLocked,
          message:
              'Des places ont déjà été réservées sans type de billet : les '
              'types ne peuvent plus être ajoutés à cet événement.',
        ),
      );
    }

    final byId = {for (final t in current) t.id: t};
    final keptIds = {
      for (final d in drafts)
        if (d.id != null) d.id!,
    };
    for (final removed in current.where((t) => !keptIds.contains(t.id))) {
      if (removed.sold > 0) {
        return Err(
          BusinessRuleFailure(
            rule: BusinessRule.tiersLocked,
            message:
                'Le billet « ${removed.name} » a déjà ${removed.sold} '
                'vente${removed.sold > 1 ? 's' : ''} : il ne peut pas être '
                'supprimé.',
          ),
        );
      }
    }

    final tiers = <EventTier>[];
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      final existing = d.id == null ? null : byId[d.id];
      final sold = existing?.sold ?? 0;
      if (d.capacity < sold) {
        return Err(
          BusinessRuleFailure(
            rule: BusinessRule.capacityBelowReservations,
            message:
                'Le billet « ${d.name} » a déjà $sold vente'
                '${sold > 1 ? 's' : ''} : sa capacité ne peut pas descendre '
                'en dessous.',
          ),
        );
      }
      tiers.add(
        EventTier(
          id: existing?.id ?? (ids ?? newId)(),
          name: d.name,
          description: d.description,
          price: d.price,
          capacity: d.capacity,
          available: d.capacity - sold,
          order: i,
        ),
      );
    }
    return Ok(
      TierPlan(
        tiers: tiers,
        capacity: tiers.fold(0, (sum, t) => sum + t.capacity),
        available: tiers.fold(0, (sum, t) => sum + t.available),
      ),
    );
  }
}
