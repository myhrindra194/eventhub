import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/recommendation.dart';
import 'package:eventhub/features/favorites/application/favorites_providers.dart';
import 'package:eventhub/features/organizers/application/organizer_directory_providers.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recommendation_providers.g.dart';

/// « Pour vous » (F-18). Vide tant que le catalogue n’est pas chargé, et
/// vide pour les organisateurs — ils ne réservent pas.
@riverpod
List<Recommendation> recommendedEvents(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isParticipant) return const [];
  final catalogue = ref.watch(catalogueProvider).value;
  if (catalogue == null) return const [];

  return Recommender.rank(
    catalogue: catalogue,
    favoriteIds: {...?ref.watch(favoriteIdsProvider).value},
    bookedEventIds: {
      for (final r
          in ref.watch(myReservationsProvider).value ?? const <Reservation>[])
        if (r.isActive) r.eventId,
    },
    followedOrganizerIds: {...?ref.watch(followingIdsProvider).value},
    now: ref.watch(clockProvider)(),
  );
}
