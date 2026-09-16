import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/moderation/data/report_remote_data_source.dart';
import 'package:eventhub/features/moderation/data/report_repository_impl.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:eventhub/features/moderation/domain/report_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'report_providers.g.dart';

@Riverpod(keepAlive: true)
ReportRepository reportRepository(Ref ref) => ReportRepositoryImpl(
  ReportRemoteDataSource(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

@riverpod
class ReportController extends _$ReportController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> submit({
    required ReportTarget target,
    required String targetId,
    required ReportReason? reason,
    required String details,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    if (ReportPolicy.validate(
          reporterId: user.id,
          target: target,
          targetId: targetId,
          reason: reason,
          details: details,
        )
        case Err(:final failure)) {
      return Err(failure);
    }

    state = const AsyncLoading();
    final result = await ref
        .read(reportRepositoryProvider)
        .submit(
          reporterId: user.id,
          target: target,
          targetId: targetId,
          reason: reason!,
          details: details,
        );
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    if (result is Ok<void>) {
      ref.read(appAnalyticsProvider).contentReported(target.name, reason.wire);
    }
    return result;
  }
}
