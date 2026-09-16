import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/admin/data/moderation_remote_data_source.dart';
import 'package:eventhub/features/admin/data/moderation_repository_impl.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/admin/domain/moderation_repository.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/notifications/application/push_dispatcher_provider.dart';
import 'package:eventhub/features/reviews/application/review_providers.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'moderation_providers.g.dart';

@Riverpod(keepAlive: true)
ModerationRepository moderationRepository(Ref ref) => ModerationRepositoryImpl(
  ModerationRemoteDataSource(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
    push: ref.watch(pushDispatcherProvider),
  ),
);

/// Rien n’est même demandé sans le rôle : les règles refuseraient chaque
/// lecture, et ouvrir un listener par écran pour se faire refuser est du
/// gaspillage.
bool _isAdmin(Ref ref) => ref.watch(currentUserProvider)?.isAdmin ?? false;

@riverpod
Stream<List<ModerationEntry>> moderationQueue(Ref ref, {required bool open}) {
  if (!_isAdmin(ref)) return Stream.value(const []);
  return ref.watch(moderationRepositoryProvider).watchQueue(open: open);
}

/// Pastille sur l’entrée de menu « Modération ».
@riverpod
int openModerationCount(Ref ref) =>
    ref.watch(moderationQueueProvider(open: true)).value?.length ?? 0;

@riverpod
Stream<ModerationEntry?> moderationEntry(Ref ref, String entryId) {
  if (!_isAdmin(ref)) return Stream.value(null);
  return ref.watch(moderationRepositoryProvider).watchEntry(entryId);
}

@riverpod
Stream<List<ReportRecord>> moderationReports(Ref ref, String entryId) {
  final parsed = ModerationEntry.parseId(entryId);
  if (!_isAdmin(ref) || parsed == null) return Stream.value(const []);
  final (target, targetId) = parsed;
  return ref
      .watch(moderationRepositoryProvider)
      .watchReports(target: target, targetId: targetId);
}

@riverpod
Stream<List<ModerationDecision>> moderationDecisions(Ref ref, String entryId) {
  if (!_isAdmin(ref)) return Stream.value(const []);
  return ref.watch(moderationRepositoryProvider).watchDecisions(entryId);
}

@riverpod
Stream<ReportedAccount?> reportedAccount(Ref ref, String userId) {
  if (!_isAdmin(ref)) return Stream.value(null);
  return ref.watch(moderationRepositoryProvider).watchAccount(userId);
}

/// Un avis signalé, masqué ou non (les règles montrent un avis masqué à son
/// auteur et aux administrateurs). [reviewId] est l’identifiant que porte
/// l’entrée.
@riverpod
Stream<Review?> moderatedReview(Ref ref, String reviewId) {
  if (reviewId.isEmpty) return Stream.value(null);
  return ref.watch(reviewRepositoryProvider).watchReviewById(reviewId);
}

@riverpod
Stream<List<AdminAccount>> adminAccounts(Ref ref) {
  if (!_isAdmin(ref)) return Stream.value(const []);
  return ref.watch(moderationRepositoryProvider).watchAdmins();
}

@riverpod
class ModerationController extends _$ModerationController {
  @override
  FutureOr<void> build() {}

  Future<Result<int?>> decide({
    required ModerationEntry entry,
    required ModerationAction action,
    required String note,
  }) async {
    if (!(ref.read(currentUserProvider)?.isAdmin ?? false)) {
      return const Err(
        PermissionFailure(message: 'Réservé à l’administration.'),
      );
    }
    state = const AsyncLoading();
    final result = await ref
        .read(moderationRepositoryProvider)
        .decide(entry: entry, action: action, note: note);
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
