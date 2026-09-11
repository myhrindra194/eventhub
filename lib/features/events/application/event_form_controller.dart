import 'dart:typed_data';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'event_form_controller.g.dart';

/// Image picked by the user, decoupled from `image_picker`'s `XFile`.
class PendingImage {
  const PendingImage({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

/// Create / update flow: optional image upload then Firestore write.
/// [existingEventId] == null means "create".
@riverpod
class EventFormController extends _$EventFormController {
  @override
  FutureOr<void> build() {}

  /// Returns the event id on success.
  Future<Result<String>> submit({
    required EventDraft draft,
    String? existingEventId,
    PendingImage? image,
  }) async {
    state = const AsyncLoading();
    final result = await _submit(draft, existingEventId, image);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    return result;
  }

  Future<Result<String>> _submit(
    EventDraft draft,
    String? existingEventId,
    PendingImage? image,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());

    var imageUrl = draft.imageUrl;
    if (image != null) {
      final upload = await ref
          .read(imageStorageRepositoryProvider)
          .uploadEventImage(
            organizerId: user.id,
            bytes: image.bytes,
            contentType: image.contentType,
          );
      switch (upload) {
        case Ok(:final value):
          imageUrl = value;
        case Err(:final failure):
          return Err(failure);
      }
    }

    final finalDraft = draft.copyWith(imageUrl: imageUrl);
    final repo = ref.read(eventRepositoryProvider);
    if (existingEventId == null) {
      return repo.create(draft: finalDraft, organizer: user);
    }
    return repo
        .update(eventId: existingEventId, draft: finalDraft, organizer: user)
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
