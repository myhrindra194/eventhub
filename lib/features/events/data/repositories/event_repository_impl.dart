import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/data/datasources/event_remote_data_source.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';
import 'package:eventhub/features/events/domain/repositories/event_repository.dart';

/// Firestore répond à une écriture refusée par un simple
/// `permission-denied` : il ne dit jamais *quelle* règle a échoué. Chaque
/// règle métier imposée par les règles de sécurité est donc vérifiée ici
/// d’abord, sur les données les plus fraîches disponibles, et traduite en
/// sa phrase française précise avant toute écriture. Les règles restent
/// l’autorité pour ce qui passe entre les mailles (une réservation
/// concurrente, un client trafiqué).
class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl({
    required EventRemoteDataSource remote,
    required Clock clock,
  }) : _remote = remote,
       _clock = clock;

  final EventRemoteDataSource _remote;
  final Clock _clock;

  @override
  Stream<List<Event>> watchUpcoming({required DateTime from}) =>
      _remote.watchUpcoming(from: from);

  @override
  Stream<List<Event>> watchByOrganizer(String organizerId) =>
      _remote.watchByOrganizer(organizerId);

  @override
  Stream<List<Event>> watchCoOrganized(String userId) =>
      _remote.watchByStaff(userId);

  @override
  Stream<Event?> watchById(String eventId) => _remote.watchById(eventId);

  @override
  AsyncResult<Event> getById(String eventId) =>
      guard(() => _remote.getById(eventId));

  @override
  AsyncResult<String> create({
    required EventDraft draft,
    required AppUser organizer,
  }) {
    return guard(() async {
      if (!organizer.isOrganizer) {
        throw const FailureException(_notOrganizer);
      }
      if (!organizer.emailVerified) {
        throw const FailureException(_emailNotVerified);
      }
      final valid = _validated(draft);
      return _remote.create(
        draft: valid,
        plan: valid.tiers.isEmpty ? null : TierPlanner.initial(valid.tiers),
        organizerId: organizer.id,
        // Les règles le comparent à `users/{uid}.name`, dont la session est
        // le miroir.
        organizerName: organizer.name,
      );
    });
  }

  @override
  AsyncResult<void> update({
    required String eventId,
    required EventDraft draft,
    required AppUser organizer,
  }) {
    return guard(() async {
      final valid = _validated(draft);
      final failure = await _remote.update(
        eventId,
        (current) => planEdit(current: current, draft: valid, user: organizer),
      );
      if (failure != null) throw FailureException(failure);
    });
  }

  /// La modification de [current] par [user], ou la règle qu’elle enfreint.
  /// Pure : elle s’exécute dans la transaction, potentiellement plusieurs
  /// fois.
  ///
  /// * seule l’équipe (propriétaire ou co-organisateur) modifie ;
  /// * avec des types, [TierPlanner.apply] préserve ce que chacun a vendu ;
  /// * sans types, la capacité ne peut pas descendre sous les places
  ///   prises.
  static ({Failure? failure, EventEdit? edit}) planEdit({
    required Event current,
    required EventDraft draft,
    required AppUser user,
  }) {
    if (EventPolicy.canManage(event: current, user: user) case Err(
      :final failure,
    )) {
      return (failure: failure, edit: null);
    }
    final tiers = TierPlanner.apply(
      soldWithoutTiers: current.hasTiers ? 0 : current.reservedCount,
      current: current.tiers,
      drafts: draft.tiers,
    );
    switch (tiers) {
      case Err(:final failure):
        return (failure: failure, edit: null);
      case Ok(value: final plan?):
        return (
          failure: null,
          edit: EventEdit(
            draft: draft,
            capacity: plan.capacity,
            availablePlaces: plan.available,
            tiers: plan.tiers,
          ),
        );
      case Ok():
        return switch (EventPolicy.availablePlacesAfterCapacityChange(
          event: current,
          newCapacity: draft.capacity,
        )) {
          Err(:final failure) => (failure: failure, edit: null),
          Ok(:final value) => (
            failure: null,
            edit: EventEdit(
              draft: draft,
              capacity: draft.capacity,
              availablePlaces: value,
              tiers: const [],
            ),
          ),
        };
    }
  }

  @override
  AsyncResult<List<Event>> fetchUpcomingAfter({
    required DateTime from,
    required Event after,
    required int limit,
  }) => guard(
    () => _remote.fetchUpcomingAfter(from: from, after: after, limit: limit),
  );

  @override
  AsyncResult<void> delete({
    required String eventId,
    required AppUser organizer,
  }) {
    return guard(() async {
      final event = await _remote.getById(eventId);
      if (EventPolicy.canDelete(event: event, user: organizer) case Err(
        :final failure,
      )) {
        throw FailureException(failure);
      }
      await _remote.delete(eventId: eventId, organizerId: organizer.id);
    });
  }

  EventDraft _validated(EventDraft draft) =>
      switch (draft.validate(now: _clock())) {
        Ok(:final value) => value,
        Err(:final failure) => throw FailureException(failure),
      };

  static const _notOrganizer = PermissionFailure(
    message: 'Seul un organisateur peut créer un événement.',
  );

  static const _emailNotVerified = BusinessRuleFailure(
    rule: BusinessRule.emailNotVerified,
    message: 'Confirmez votre adresse email pour publier un événement.',
  );
}
