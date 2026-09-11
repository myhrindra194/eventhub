import 'dart:typed_data';

import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/mock/mock_store.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/in_memory_images.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';
import 'package:eventhub/features/events/domain/repositories/event_repository.dart';
import 'package:eventhub/features/events/domain/repositories/image_storage_repository.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/policies/reservation_policy.dart';
import 'package:eventhub/features/reservations/domain/repositories/reservation_repository.dart';

/// Simulated network latency so loading states are visible in the demo.
const _latency = Duration(milliseconds: 350);

Future<T> _simulate<T>(T Function() body) => Future.delayed(_latency, body);

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._store);

  final MockStore _store;

  @override
  Stream<AuthSession> watchSession() => _store.session.stream;

  @override
  AsyncResult<AppUser> signIn({
    required String email,
    required String password,
  }) {
    return guard(
      () => _simulate(() {
        final account = _store.accounts[email.trim().toLowerCase()];
        if (account == null || account.password != password) {
          throw const FailureException(
            AuthFailure(
              code: AuthFailureCode.invalidCredentials,
              message: 'Email ou mot de passe incorrect.',
            ),
          );
        }
        _store.session.add(SignedIn(account.user));
        return account.user;
      }),
    );
  }

  @override
  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    return guard(
      () => _simulate(() {
        final key = email.trim().toLowerCase();
        if (_store.accounts.containsKey(key)) {
          throw const FailureException(
            AuthFailure(
              code: AuthFailureCode.emailAlreadyInUse,
              message: 'Un compte existe déjà avec cet email.',
            ),
          );
        }
        final user = AppUser(
          id: 'user-${DateTime.now().microsecondsSinceEpoch}',
          name: name.trim(),
          email: key,
          role: role,
          createdAt: DateTime.now(),
        );
        _store.accounts[key] = (user: user, password: password);
        _store.session.add(SignedIn(user));
        return user;
      }),
    );
  }

  @override
  AsyncResult<AppUser> completeProfile({
    required String name,
    required UserRole role,
  }) => Future.value(const Err<AppUser>(AuthFailure.notSignedIn()));

  @override
  AsyncResult<void> sendPasswordReset({required String email}) =>
      guard(() => _simulate(() {}));

  @override
  AsyncResult<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return guard(
      () => _simulate(() {
        final user = _store.session.value.userOrNull;
        if (user == null) {
          throw const FailureException(AuthFailure.notSignedIn());
        }
        final account = _store.accounts[user.email];
        if (account == null || account.password != currentPassword) {
          throw const FailureException(
            AuthFailure(
              code: AuthFailureCode.invalidCredentials,
              message: 'Mot de passe actuel incorrect.',
            ),
          );
        }
        _store.accounts[user.email] = (user: user, password: newPassword);
      }),
    );
  }

  @override
  AsyncResult<void> signOut() =>
      guard(() => _simulate(() => _store.session.add(const SignedOut())));
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

class MockEventRepository implements EventRepository {
  MockEventRepository(this._store, this._clock);

  final MockStore _store;
  final Clock _clock;

  List<Event> get _all => _store.events.value;

  void _emit(List<Event> events) =>
      _store.events.add(List.unmodifiable(events));

  @override
  Stream<List<Event>> watchUpcoming({required DateTime from}) =>
      _store.events.map(
        (list) =>
            list.where((e) => !e.startsAt.isBefore(from)).toList()
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
      );

  @override
  Stream<List<Event>> watchByOrganizer(String organizerId) => _store.events.map(
    (list) =>
        list.where((e) => e.organizerId == organizerId).toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt)),
  );

  @override
  Stream<Event?> watchById(String eventId) => _store.events.map(
    (list) => list.where((e) => e.id == eventId).firstOrNull,
  );

  @override
  AsyncResult<Event> getById(String eventId) => guard(() => _find(eventId));

  Event _find(String eventId) {
    final event = _all.where((e) => e.id == eventId).firstOrNull;
    if (event == null) {
      throw FailureException(
        NotFoundFailure(
          resource: 'events/$eventId',
          message: 'Événement introuvable.',
        ),
      );
    }
    return event;
  }

  @override
  AsyncResult<String> create({
    required EventDraft draft,
    required AppUser organizer,
  }) {
    return guard(
      () => _simulate(() {
        final valid = _validated(draft);
        final id = 'evt-${DateTime.now().millisecondsSinceEpoch}';
        _emit([
          ..._all,
          Event(
            id: id,
            title: valid.title,
            description: valid.description,
            category: valid.category,
            startsAt: valid.startsAt,
            location: valid.location,
            capacity: valid.capacity,
            availablePlaces: valid.capacity,
            organizerId: organizer.id,
            organizerName: organizer.name,
            imageUrl: valid.imageUrl,
            createdAt: _clock(),
            updatedAt: _clock(),
          ),
        ]);
        return id;
      }),
    );
  }

  @override
  AsyncResult<void> update({
    required String eventId,
    required EventDraft draft,
    required AppUser organizer,
  }) {
    return guard(
      () => _simulate(() {
        final current = _find(eventId);
        if (EventPolicy.canManage(event: current, user: organizer) case Err(
          :final failure,
        )) {
          throw FailureException(failure);
        }
        final valid = _validated(draft);
        final available =
            switch (EventPolicy.availablePlacesAfterCapacityChange(
              event: current,
              newCapacity: valid.capacity,
            )) {
              Ok(:final value) => value,
              Err(:final failure) => throw FailureException(failure),
            };
        _emit([
          for (final e in _all)
            if (e.id == eventId)
              e.copyWith(
                title: valid.title,
                description: valid.description,
                category: valid.category,
                startsAt: valid.startsAt,
                location: valid.location,
                capacity: valid.capacity,
                availablePlaces: available,
                imageUrl: valid.imageUrl,
                updatedAt: _clock(),
              )
            else
              e,
        ]);
      }),
    );
  }

  @override
  AsyncResult<void> delete({
    required String eventId,
    required AppUser organizer,
  }) {
    return guard(
      () => _simulate(() {
        final current = _find(eventId);
        if (EventPolicy.canManage(event: current, user: organizer) case Err(
          :final failure,
        )) {
          throw FailureException(failure);
        }
        _emit(_all.where((e) => e.id != eventId).toList());
      }),
    );
  }

  EventDraft _validated(EventDraft draft) =>
      switch (draft.validate(now: _clock())) {
        Ok(:final value) => value,
        Err(:final failure) => throw FailureException(failure),
      };
}

// ---------------------------------------------------------------------------
// Reservations
// ---------------------------------------------------------------------------

class MockReservationRepository implements ReservationRepository {
  MockReservationRepository(this._store, this._clock);

  final MockStore _store;
  final Clock _clock;

  List<Reservation> get _all => _store.reservations.value;

  @override
  Stream<List<Reservation>> watchByUser(String userId) =>
      _store.reservations.map(
        (list) =>
            list.where((r) => r.userId == userId).toList()
              ..sort((a, b) => b.reservedAt.compareTo(a.reservedAt)),
      );

  @override
  Stream<List<Reservation>> watchByEvent({
    required String eventId,
    required String organizerId,
  }) => _store.reservations.map(
    (list) =>
        list
            .where(
              (r) =>
                  r.eventId == eventId &&
                  r.organizerId == organizerId &&
                  r.isActive,
            )
            .toList()
          ..sort((a, b) => b.reservedAt.compareTo(a.reservedAt)),
  );

  @override
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  }) => watchById(Reservation.composeId(eventId: eventId, userId: userId));

  @override
  Stream<Reservation?> watchById(String reservationId) => _store.reservations
      .map((list) => list.where((r) => r.id == reservationId).firstOrNull);

  @override
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
  }) {
    return guard(
      () => _simulate(() {
        final events = _store.events.value;
        final event = events.where((e) => e.id == eventId).firstOrNull;
        if (event == null) {
          throw const FailureException(
            NotFoundFailure(
              resource: 'events',
              message: 'Cet événement n\'existe plus.',
            ),
          );
        }
        final id = Reservation.composeId(
          eventId: eventId,
          userId: participant.id,
        );
        final existing = _all.where((r) => r.id == id).firstOrNull;
        final now = _clock();
        if (ReservationPolicy.canReserve(
              event: event,
              existing: existing,
              now: now,
            )
            case Err(:final failure)) {
          throw FailureException(failure);
        }
        final reservation = Reservation(
          id: id,
          eventId: event.id,
          userId: participant.id,
          organizerId: event.organizerId,
          userName: participant.name,
          userEmail: participant.email,
          eventTitle: event.title,
          eventStartsAt: event.startsAt,
          eventLocation: event.location,
          status: ReservationStatus.confirmed,
          reservedAt: now,
        );
        _store.reservations.add([
          ..._all.where((r) => r.id != id),
          reservation,
        ]);
        _store.events.add([
          for (final e in events)
            if (e.id == eventId)
              e.copyWith(availablePlaces: e.availablePlaces - 1, updatedAt: now)
            else
              e,
        ]);
        return reservation;
      }),
    );
  }

  @override
  AsyncResult<void> cancel({
    required String reservationId,
    required AppUser participant,
  }) {
    return guard(
      () => _simulate(() {
        final reservation = _all
            .where((r) => r.id == reservationId)
            .firstOrNull;
        if (reservation == null) {
          throw const FailureException(
            NotFoundFailure(
              resource: 'reservations',
              message: 'Réservation introuvable.',
            ),
          );
        }
        if (ReservationPolicy.canCancel(
              reservation: reservation,
              userId: participant.id,
            )
            case Err(:final failure)) {
          throw FailureException(failure);
        }
        final now = _clock();
        _store.reservations.add([
          for (final r in _all)
            if (r.id == reservationId)
              r.copyWith(status: ReservationStatus.cancelled, cancelledAt: now)
            else
              r,
        ]);
        _store.events.add([
          for (final e in _store.events.value)
            if (e.id == reservation.eventId)
              e.copyWith(availablePlaces: e.availablePlaces + 1, updatedAt: now)
            else
              e,
        ]);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Image storage
// ---------------------------------------------------------------------------

class MockImageStorageRepository implements ImageStorageRepository {
  const MockImageStorageRepository();

  @override
  AsyncResult<String> uploadEventImage({
    required String organizerId,
    required Uint8List bytes,
    required String contentType,
  }) {
    return guard(() => _simulate(() => InMemoryImages.put(bytes)));
  }
}
