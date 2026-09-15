import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reviews/data/review_remote_data_source.dart';
import 'package:eventhub/features/reviews/data/review_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records the writes and throws what `public.reviews` would answer.
class _FakeReviews implements ReviewRemoteDataSource {
  _FakeReviews({this.createError});

  final PostgrestException? createError;
  final calls = <String>[];

  @override
  Future<void> create({
    required String eventId,
    required int rating,
    required String comment,
  }) async {
    calls.add('create $eventId $rating "$comment"');
    if (createError case final e?) throw e;
  }

  @override
  Future<void> update({
    required String eventId,
    required String authorId,
    required int rating,
    required String comment,
  }) async {
    calls.add('update $eventId $authorId $rating "$comment"');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const eventId = '0b6f7c1e-8d2a-4f3b-9e5c-1a2b3c4d5e6f';
  const userId = '9c8b7a6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d';
  final now = DateTime(2026, 9, 14, 12);
  const user = AppUser(
    id: userId,
    name: 'Soa',
    email: 'soa@example.com',
    role: UserRole.participant,
    emailVerified: true,
  );
  final reservation = Reservation(
    id: '1d2c3b4a-5f6e-4d7c-8b9a-0f1e2d3c4b5a',
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

  Future<Result<void>> save(_FakeReviews remote, {bool exists = false}) =>
      ReviewRepositoryImpl(remote).save(
        user: user,
        reservation: reservation,
        eventId: eventId,
        rating: 4,
        comment: '  Très bien  ',
        exists: exists,
        now: now,
      );

  test('inserts only event, rating and trimmed comment', () async {
    final remote = _FakeReviews();
    expect(await save(remote), isA<Ok<void>>());
    expect(remote.calls, ['create $eventId 4 "Très bien"']);
  });

  test('edits by (event, author) when the review exists', () async {
    final remote = _FakeReviews();
    expect(await save(remote, exists: true), isA<Ok<void>>());
    expect(remote.calls, ['update $eventId $userId 4 "Très bien"']);
  });

  test('falls back to an edit when the review was created meanwhile', () async {
    final remote = _FakeReviews(
      createError: const PostgrestException(message: 'dup', code: '23505'),
    );
    expect(await save(remote), isA<Ok<void>>());
    expect(remote.calls.last, 'update $eventId $userId 4 "Très bien"');
  });

  test(
    'an insert refused by RLS means the person is not an attendee',
    () async {
      final result = await save(
        _FakeReviews(
          createError: const PostgrestException(
            message: 'new row violates row-level security policy',
            code: '42501',
          ),
        ),
      );
      expect(
        result,
        isA<Err<void>>().having(
          (e) => (e.failure as BusinessRuleFailure).rule,
          'rule',
          BusinessRule.notAttendee,
        ),
      );
    },
  );
}
