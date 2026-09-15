import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'event_form_controller.g.dart';

/// Create / update flow. [existingEventId] == null means "create".
///
/// The cover is an https URL typed in the form (see [EventDraft.imageUrl]):
/// on the Spark plan there is no Cloud Storage to upload to, and an event
/// without a cover keeps its generated visual.
@riverpod
class EventFormController extends _$EventFormController {
  @override
  FutureOr<void> build() {}

  /// Returns the event id on success.
  Future<Result<String>> submit({
    required EventDraft draft,
    String? existingEventId,
  }) async {
    state = const AsyncLoading();
    final result = await _submit(draft, existingEventId);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    if (result case Ok(:final value) when existingEventId == null) {
      ref.read(appAnalyticsProvider).eventPublished(value);
    }
    return result;
  }

  Future<Result<String>> _submit(
    EventDraft draft,
    String? existingEventId,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    // The rules read `email_verified` from the token on creation: say so
    // instead of letting the write come back as a bare refusal.
    if (existingEventId == null && !user.emailVerified) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.emailNotVerified,
          message: AppStrings.emailNotVerifiedForEvent,
        ),
      );
    }

    final repo = ref.read(eventRepositoryProvider);
    if (existingEventId == null) {
      return repo.create(draft: draft, organizer: user);
    }
    return repo
        .update(eventId: existingEventId, draft: draft, organizer: user)
        .mapAsync((_) => existingEventId);
  }
}

/// Destructive actions on an existing event.
@riverpod
class EventActionsController extends _$EventActionsController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> delete(String eventId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());

    state = const AsyncLoading();
    final result = await ref
        .read(eventRepositoryProvider)
        .delete(eventId: eventId, organizer: user);
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
