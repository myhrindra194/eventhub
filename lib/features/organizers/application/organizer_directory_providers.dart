import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_remote_data_source.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_repository_impl.dart';
import 'package:eventhub/features/organizers/domain/organizer_directory_repository.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'organizer_directory_providers.g.dart';

@Riverpod(keepAlive: true)
OrganizerDirectoryRepository organizerDirectoryRepository(Ref ref) =>
    OrganizerDirectoryRepositoryImpl(
      OrganizerDirectoryRemoteDataSource(ref.watch(supabaseClientProvider)),
    );

@riverpod
Stream<OrganizerProfile?> organizerProfile(Ref ref, String organizerId) =>
    ref.watch(organizerDirectoryRepositoryProvider).watchProfile(organizerId);

/// Organizers the signed-in user follows (either role may follow).
@riverpod
Stream<List<String>> followingIds(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref
      .watch(organizerDirectoryRepositoryProvider)
      .watchFollowingIds(user.id);
}

@riverpod
bool isFollowing(Ref ref, String organizerId) =>
    ref.watch(followingIdsProvider).value?.contains(organizerId) ?? false;

@riverpod
class FollowController extends _$FollowController {
  @override
  FutureOr<void> build() {}

  /// The button flips when Realtime echoes the row back (a fraction of a
  /// second); the public counter follows, maintained by a trigger.
  Future<Result<void>> toggle(String organizerId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    if (FollowPolicy.canFollow(user: user, organizerId: organizerId) case Err(
      :final failure,
    )) {
      return Err(failure);
    }

    final following = ref.read(isFollowingProvider(organizerId));
    final repo = ref.read(organizerDirectoryRepositoryProvider);
    state = const AsyncLoading();
    final result = following
        ? await repo.unfollow(userId: user.id, organizerId: organizerId)
        : await repo.follow(userId: user.id, organizerId: organizerId);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    if (result is Ok<void>) {
      ref.read(appAnalyticsProvider).follow(organizerId, added: !following);
    }
    return result;
  }
}
