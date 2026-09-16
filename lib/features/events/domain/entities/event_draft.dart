import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/money.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_draft.freezed.dart';

/// Saisie utilisateur pour créer ou modifier un événement. Les champs qui
/// appartiennent au serveur (id, organizer, availablePlaces, horodatages)
/// en sont délibérément absents.
@freezed
abstract class EventDraft with _$EventDraft {
  const EventDraft._();

  const factory EventDraft({
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startsAt,
    required String location,

    /// Ignorée quand [tiers] n’est pas vide : la capacité est alors leur
    /// somme.
    required int capacity,

    /// Image de couverture : le lien `https://` rendu par Cloudinary après
    /// l’import (Cloud Storage exigerait le plan Blaze). Vide signifie
    /// aucune : l’événement conserve son visuel généré.
    String? imageUrl,

    /// Types de billets (F-12). Vide : un unique pool gratuit de
    /// [capacity] places.
    @Default(<EventTierDraft>[]) List<EventTierDraft> tiers,

    /// Obligatoire dès qu’un type de billet est payant.
    String? currency,
  }) = _EventDraft;

  static const titleMinLength = 3;
  static const maxCapacity = 100000;

  /// Même plafond que les règles de sécurité (`isHttpsUrl`).
  static const maxImageUrlLength = 2048;

  /// `null` quand [value] est vide ou constitue un lien de couverture
  /// exploitable, sinon la phrase à afficher sous le champ.
  ///
  /// Le lien vient désormais de l’import, plus d’une saisie : ce contrôle est
  /// un filet contre un état incohérent, pas une aide à la frappe. Il reste
  /// volontairement plus large que les règles (qui n’acceptent qu’un
  /// nouveau lien Cloudinary) pour qu’un événement dont la couverture est un
  /// ancien lien collé puisse encore être modifié sans la perdre.
  static String? imageUrlError(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null;
    if (url.length > maxImageUrlLength) {
      return 'Le lien est trop long ($maxImageUrlLength caractères au plus).';
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        url.contains(RegExp(r'\s'))) {
      return 'Le lien de l’image est invalide. Importez-la de nouveau.';
    }
    return null;
  }

  int get totalCapacity =>
      tiers.isEmpty ? capacity : tiers.fold(0, (sum, t) => sum + t.capacity);

  bool get hasPaidTier => tiers.any((t) => t.price > 0);

  /// Validation métier, indépendante de tout widget de formulaire.
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
    if (imageUrlError(imageUrl) case final error?) {
      errors['imageUrl'] = error;
    }
    final cover = imageUrl?.trim() ?? '';
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
        imageUrl: cover.isEmpty ? null : cover,
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
