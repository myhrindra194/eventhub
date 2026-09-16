import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/team/data/team_remote_data_source.dart';
import 'package:eventhub/features/team/data/team_repository_impl.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:eventhub/features/team/domain/team_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'team_providers.g.dart';

@Riverpod(keepAlive: true)
TeamRepository teamRepository(Ref ref) => TeamRepositoryImpl(
  TeamRemoteDataSource(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

@riverpod
Stream<List<StaffInvitation>> eventPendingInvitations(
  Ref ref,
  String eventId,
) => ref.watch(teamRepositoryProvider).watchPendingForEvent(eventId);

/// Invitations en attente de la réponse de l’organisateur connecté.
@riverpod
Stream<List<StaffInvitation>> myStaffInvitations(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isOrganizer) return Stream.value(const []);
  return ref.watch(teamRepositoryProvider).watchPendingForUser(user.id);
}

@riverpod
class TeamController extends _$TeamController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> invite({
    required String eventId,
    required String email,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    final event = ref.read(eventByIdProvider(eventId)).value;
    if (event == null) {
      return const Err(
        NotFoundFailure(resource: 'event', message: 'Événement introuvable.'),
      );
    }
    final pending =
        ref.read(eventPendingInvitationsProvider(eventId)).value?.length ?? 0;
    if (TeamPolicy.canInvite(
          event: event,
          user: user,
          email: email,
          pendingCount: pending,
          now: ref.read(clockProvider)(),
        )
        case Err(:final failure)) {
      return Err(failure);
    }
    return _run(
      () => ref
          .read(teamRepositoryProvider)
          .invite(eventId: eventId, email: email),
    );
  }

  Future<Result<void>> respond({
    required String eventId,
    required bool accept,
  }) => _run(
    () => ref
        .read(teamRepositoryProvider)
        .respond(eventId: eventId, accept: accept),
  );

  Future<Result<void>> remove({
    required String eventId,
    required String userId,
  }) => _run(
    () => ref
        .read(teamRepositoryProvider)
        .remove(eventId: eventId, userId: userId),
  );

  Future<Result<void>> _run(AsyncResult<void> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    return result;
  }
}
