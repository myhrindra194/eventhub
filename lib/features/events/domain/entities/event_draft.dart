import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_draft.freezed.dart';

/// User input for creating or editing an event. Server-owned fields
/// (id, organizer, availablePlaces, timestamps) are deliberately absent.
@freezed
abstract class EventDraft with _$EventDraft {
  const EventDraft._();

  const factory EventDraft({
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startsAt,
    required String location,
    required int capacity,
    String? imageUrl,
  }) = _EventDraft;

  static const titleMinLength = 3;
  static const maxCapacity = 100000;

  /// Domain validation, independent from any form widget.
  Result<EventDraft> validate({required DateTime now}) {
    final errors = <String, String>{};
    if (title.trim().length < titleMinLength) {
      errors['title'] =
          'Le titre doit contenir au moins $titleMinLength caractères.';
    }
    if (description.trim().isEmpty) {
      errors['description'] = 'La description est obligatoire.';
    }
    if (location.trim().isEmpty) {
      errors['location'] = 'Le lieu est obligatoire.';
    }
    if (capacity <= 0 || capacity > maxCapacity) {
      errors['capacity'] =
          'La capacité doit être comprise entre 1 et $maxCapacity.';
    }
    if (!startsAt.isAfter(now)) {
      errors['startsAt'] = "La date de l'événement doit être dans le futur.";
    }
    if (errors.isNotEmpty) {
      return Err(
        ValidationFailure(
          message: 'Certains champs sont invalides.',
          fieldErrors: errors,
        ),
      );
    }
    return Ok(
      copyWith(
        title: title.trim(),
        description: description.trim(),
        location: location.trim(),
      ),
    );
  }
}
