import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/money.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
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

    /// Ignored when [tiers] is not empty: the capacity is then their sum.
    required int capacity,
    String? imageUrl,

    /// Ticket types (F-12). Empty: one free pool of [capacity] seats.
    @Default(<EventTierDraft>[]) List<EventTierDraft> tiers,

    /// Required as soon as one type is paid.
    String? currency,
  }) = _EventDraft;

  static const titleMinLength = 3;
  static const maxCapacity = 100000;

  int get totalCapacity =>
      tiers.isEmpty ? capacity : tiers.fold(0, (sum, t) => sum + t.capacity);

  bool get hasPaidTier => tiers.any((t) => t.price > 0);

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
    if (tiers.isEmpty) {
      if (capacity <= 0 || capacity > maxCapacity) {
        errors['capacity'] =
            'La capacité doit être comprise entre 1 et $maxCapacity.';
      }
    } else {
      final tierError = _tierError();
      if (tierError != null) errors['tiers'] = tierError;
      if (hasPaidTier && !Money.currencies.contains(currency)) {
        errors['currency'] = 'Choisissez la devise des billets payants.';
      }
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
        capacity: totalCapacity,
        currency: hasPaidTier ? currency : null,
        tiers: [
          for (final t in tiers)
            t.copyWith(name: t.name.trim(), description: t.description.trim()),
        ],
      ),
    );
  }

  String? _tierError() {
    if (tiers.length > EventTier.maxTiers) {
      return '${EventTier.maxTiers} types de billets au plus.';
    }
    final names = <String>{};
    for (final t in tiers) {
      final name = t.name.trim();
      if (name.isEmpty || name.length > EventTier.maxNameLength) {
        return 'Chaque type de billet a un nom de 1 à '
            '${EventTier.maxNameLength} caractères.';
      }
      if (!names.add(name.toLowerCase())) {
        return 'Deux types de billets portent le nom « $name ».';
      }
      if (t.description.trim().length > EventTier.maxDescriptionLength) {
        return 'La description de « $name » dépasse '
            '${EventTier.maxDescriptionLength} caractères.';
      }
      if (t.capacity <= 0) {
        return 'Le billet « $name » doit proposer au moins une place.';
      }
      if (t.price < 0 || t.price > Money.maxAmount) {
        return 'Le prix du billet « $name » est invalide.';
      }
    }
    if (totalCapacity > maxCapacity) {
      return 'La capacité totale ne peut pas dépasser $maxCapacity places.';
    }
    return null;
  }
}
