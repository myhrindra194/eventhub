import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reviews/data/review_remote_data_source.dart';
import 'package:eventhub/features/reviews/data/review_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ReviewRemoteDataSource {}

void main() {
  const eventId = 'Xk3Pq9LmZr2Tb7Wc4Yd1';
  const userId = 'aB3dE5fG7hJ9kL1mN3pQ5rS7tU9';
  final now = DateTime(2026, 9, 14, 12);
  const user = AppUser(
    id: userId,
    name: 'Soa',
    email: 'soa@example.com',
    role: UserRole.participant,
    emailVerified: true,
  );
  final reservation = Reservation(
    id: '${eventId}_$userId',
    eventId: eventId,
    userId: userId,
    organizerId: 'org',
    userName: 'Soa',
    userEmail: 'soa@example.com',
    eventTitle: 'Flutter Meetup',
    eventStartsAt: now.subtract(const Duration(days: 1)),
    eventLocation: 'Antananarivo',
    status: ReservationStatus.confirmed,
    reservedAt: now.subtract(const Duration(days: 10)),
  );

  late _MockRemote remote;

  setUpAll(() => registerFallbackValue(user));

  setUp(() {
    remote = _MockRemote();
  });

  void stubSave({Object? error}) =>
      when(
        () => remote.save(
          eventId: any(named: 'eventId'),
          organizerId: any(named: 'organizerId'),
          author: any(named: 'author'),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async {
        if (error != null) throw error;
      });

  Future<Result<void>> save({Reservation? seat, int rating = 4}) =>
      ReviewRepositoryImpl(remote).save(
        user: user,
        reservation: seat ?? reservation,
        eventId: eventId,
        rating: rating,
        comment: '  Très bien  ',
        now: now,
      );

  test('writes a trimmed review counted for the event\'s organizer', () async {
    stubSave();
    expect(await save(), isA<Ok<void>>());
    verify(
      () => remote.save(
        eventId: eventId,
        organizerId: 'org',
        author: user,
        rating: 4,
        comment: 'Très bien',
      ),
    ).called(1);
  });

  test('nothing is written when the policy refuses', () async {
    stubSave();
    final notStarted = reservation.copyWith(
      eventStartsAt: now.add(const Duration(hours: 2)),
    );
    final result = await save(seat: notStarted);
    expect(
      (result.failureOrNull! as BusinessRuleFailure).rule,
      BusinessRule.eventNotStarted,
    );
    expect(await save(rating: 6), isA<Err<void>>());
    verifyNever(
      () => remote.save(
        eventId: any(named: 'eventId'),
        organizerId: any(named: 'organizerId'),
        author: any(named: 'author'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    );
  });

  test(
    'a write refused by the rules means the person did not attend',
    () async {
      stubSave(
        error: FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );
      final result = await save();
      expect(
        (result.failureOrNull! as BusinessRuleFailure).rule,
        BusinessRule.notAttendee,
      );
    },
  );

  test('other Firestore errors keep their own meaning', () async {
    stubSave(
      error: FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
    expect((await save()).failureOrNull, isA<NetworkFailure>());
  });

  test('deletes the author\'s own review', () async {
    when(
      () => remote.delete(eventId: eventId, authorId: userId),
    ).thenAnswer((_) async {});
    final result = await ReviewRepositoryImpl(
      remote,
    ).delete(eventId: eventId, userId: userId);
    expect(result, isA<Ok<void>>());
    verify(() => remote.delete(eventId: eventId, authorId: userId)).called(1);
  });
}
