import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:eventhub/features/reviews/domain/review_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 14, 12);

  AppUser user({UserRole role = UserRole.participant, bool verified = true}) =>
      AppUser(
        id: 'u1',
        name: 'Jean',
        email: 'jean@example.com',
        role: role,
        emailVerified: verified,
      );

  Reservation reservation({
    DateTime? startsAt,
    ReservationStatus status = ReservationStatus.confirmed,
  }) => Reservation(
    id: 'e1_u1',
    eventId: 'e1',
    userId: 'u1',
    organizerId: 'o1',
    userName: 'Jean',
    userEmail: 'jean@example.com',
    eventTitle: 'Flutter Meetup',
    eventStartsAt: startsAt ?? now.subtract(const Duration(days: 1)),
    eventLocation: 'Antananarivo',
    status: status,
    reservedAt: now.subtract(const Duration(days: 10)),
  );

  BusinessRule? rule(Result<void> r) => switch (r) {
    Err(failure: final BusinessRuleFailure f) => f.rule,
    _ => null,
  };

  group('canReview', () {
    test('allows a verified attendee once the event has started', () {
      expect(
        ReviewPolicy.canReview(
          user: user(),
          reservation: reservation(),
          now: now,
        ),
        isA<Ok<void>>(),
      );
    });

    test('an organizer account who attended reviews like anyone', () {
      expect(
        ReviewPolicy.canReview(
          user: user(role: UserRole.organizer),
          reservation: reservation(),
          now: now,
        ),
        isA<Ok<void>>(),
      );
    });

    test("refuses non-attendees, cancelled seats and someone else's", () {
      for (final (u, r) in [
        (user(), null),
        (user(), reservation(status: ReservationStatus.cancelled)),
        (user().copyWith(id: 'u2'), reservation()),
      ]) {
        expect(
          rule(ReviewPolicy.canReview(user: u, reservation: r, now: now)),
          BusinessRule.notAttendee,
        );
      }
    });

    test('opens only when the event starts, and needs a verified email', () {
      expect(
        rule(
          ReviewPolicy.canReview(
            user: user(),
            reservation: reservation(
              startsAt: now.add(const Duration(hours: 1)),
            ),
            now: now,
          ),
        ),
        BusinessRule.eventNotStarted,
      );
      expect(
        rule(
          ReviewPolicy.canReview(
            user: user(verified: false),
            reservation: reservation(),
            now: now,
          ),
        ),
        BusinessRule.emailNotVerified,
      );
    });
  });

  test('validate bounds rating and comment', () {
    expect(ReviewPolicy.validate(rating: 5, comment: 'Top'), isA<Ok<void>>());
    final bad = ReviewPolicy.validate(rating: 0, comment: 'x' * 2001);
    expect(bad, isA<Err<void>>());
    final failure = (bad as Err<void>).failure as ValidationFailure;
    expect(failure.fieldErrors.keys, containsAll(['rating', 'comment']));
  });

  test('ReviewSummary averages and ignores out-of-range ratings', () {
    Review r(int rating) => Review(
      id: 'r$rating',
      eventId: 'e1',
      authorId: 'a$rating',
      authorName: 'A',
      rating: rating,
      comment: '',
      createdAt: now,
    );
    final summary = ReviewSummary.of([r(5), r(4), r(4), r(9)]);
    expect(summary.count, 3);
    expect(summary.average, closeTo(13 / 3, 1e-9));
    expect(summary.distribution, [0, 0, 0, 2, 1]);
    expect(ReviewSummary.of(const []).average, 0);
  });
}
