import 'dart:math' as math;

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_tier.freezed.dart';

/// A ticket type of an event (F-12): "Standard", "Étudiant", "VIP"…
///
/// Stored in the event document as `tiers.{id}`, so a booking decrements the
/// type and the event in the same write, which the security rules check.
/// [price] is in the currency's minor unit (see `Money`); 0 means free.
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

  /// Ids are short lowercase tokens: they appear in field paths
  /// (`tiers.{id}.available`) and in the Stripe metadata.
  static bool isValidId(String id) => RegExp(r'^[a-z0-9]{1,20}$').hasMatch(id);
}

/// A ticket type as typed in the event form. [id] is null for a new type.
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

/// Ticket types ready to be written, with the event totals they imply.
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

/// Turns form input into ticket types, keeping every seat already sold.
/// Pure: the Firestore transaction calls it with the event it just read.
abstract final class TierPlanner {
  static String newId([math.Random? random]) {
    final r = random ?? math.Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return 't${List.generate(7, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  /// A new event: every seat of every type is available.
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

  /// An edit. `null` means the event stays (or becomes) a simple event
  /// without types.
  ///
  /// * a type may not go below what it already sold, nor be removed once it
  ///   sold anything;
  /// * types cannot be added to, or removed from, an event that already has
  ///   bookings in the other mode — those reservations could not give their
  ///   seat back to the right counter.
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
