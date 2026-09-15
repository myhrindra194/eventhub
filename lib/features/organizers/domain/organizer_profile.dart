import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';

/// `public.organizers` — the public face of an organizer (F-10).
///
/// Every field is derived server-side: name and bio are copied from the
/// private profile by a trigger, the counters are maintained by triggers on
/// follows, events and reviews. The client only reads it, which is what
/// makes a follower count or a rating worth showing.
class OrganizerProfile {
  const OrganizerProfile({
    required this.id,
    required this.name,
    this.bio = '',
    this.followerCount = 0,
    this.eventCount = 0,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.memberSince,
  });

  final String id;
  final String name;
  final String bio;
  final int followerCount;

  /// Events ever published and not deleted, past ones included.
  final int eventCount;

  /// Over the visible reviews of all their events.
  final int ratingSum;
  final int ratingCount;
  final DateTime? memberSince;

  /// `null` until someone reviewed one of their events. Clamped, so a
  /// counter caught mid-update never renders "5,3 / 5".
  double? get averageRating =>
      ratingCount <= 0 ? null : (ratingSum / ratingCount).clamp(1.0, 5.0);

  bool get hasBio => bio.trim().isNotEmpty;
}

/// Mirrors the `follows_not_self` constraint, so the button explains itself
/// instead of waiting for the database to refuse.
abstract final class FollowPolicy {
  static Result<void> canFollow({
    required AppUser user,
    required String organizerId,
  }) {
    if (organizerId.isEmpty) {
      return const Err(ValidationFailure(message: 'Organisateur inconnu.'));
    }
    if (organizerId == user.id) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.cannotFollowSelf,
          message: 'Vous ne pouvez pas vous abonner à votre propre profil.',
        ),
      );
    }
    return const Ok(null);
  }
}
