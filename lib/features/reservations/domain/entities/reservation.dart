import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation.freezed.dart';

enum ReservationStatus {
  confirmed,

  /// Une place payante retenue pendant que l’acheteur paie (F-11).
  /// Conservée dans le domaine pour le jour où un serveur de paiement
  /// existera ; sur le plan Spark elle n’est jamais écrite (les règles de
  /// sécurité n’acceptent que `confirmed` et `cancelled`).
  pending,
  cancelled;

  String get label => switch (this) {
    ReservationStatus.confirmed => 'Confirmée',
    ReservationStatus.pending => 'Paiement en cours',
    ReservationStatus.cancelled => 'Annulée',
  };
}

/// La place d’un participant sur un événement.
///
/// Les champs de l’événement et de l’utilisateur sont dénormalisés pour que
/// « Mes réservations » et la liste des participants de l’organisateur
/// s’affichent sans lectures N+1, et continuent de fonctionner si
/// l’événement est supprimé par la suite.
///
/// L’id est déterministe : `DocIds.reservation(eventId, userId)`, soit
/// `<eventId>_<userId>`. C’est ainsi que la règle « une place par personne
/// et par événement » tient sans index unique — il n’y a qu’un seul
/// document à écrire — et ainsi que les règles de sécurité retrouvent la
/// place de l’appelant pour prouver une réservation, une annulation ou une
/// présence. Réserver à nouveau après une annulation réécrit le même
/// document, et conserve donc le même code de billet.
@freezed
abstract class Reservation with _$Reservation {
  const Reservation._();

  const factory Reservation({
    required String id,

    /// Vide une fois l’événement supprimé : la réservation demeure à titre
    /// d’historique, avec son instantané de titre, de date et de lieu.
    required String eventId,

    /// Vide une fois le compte du participant supprimé (la ligne est
    /// anonymisée et conservée pour les statistiques de l’organisateur).
    required String userId,

    /// Vide une fois le compte de l’organisateur supprimé.
    required String organizerId,
    required String userName,
    required String userEmail,
    required String eventTitle,
    required DateTime eventStartsAt,
    required String eventLocation,
    required ReservationStatus status,
    required DateTime reservedAt,
    DateTime? cancelledAt,

    /// Qui a annulé : l’uid du titulaire, ou `moderation` lorsqu’un
    /// administrateur a retiré l’événement.
    String? cancelledBy,

    /// Type de billet (F-12), copié au moment de la réservation.
    String? tierId,
    String? tierName,

    /// Montant réellement payé, en unités mineures. Toujours 0 sans serveur
    /// de paiement : les règles refusent toute autre valeur.
    @Default(0) int pricePaid,

    // Champs de paiement (F-11). Jamais stockés sur le plan Spark — aucun
    // serveur ne peut encaisser — et restent donc nuls ; les écrans de
    // paiement continuent de les lire pour le jour où un backend de
    // paiement sera ajouté.
    int? amountDue,
    String? currency,
    String? paymentStatus,
    String? checkoutUrl,
    DateTime? holdExpiresAt,
  }) = _Reservation;

  /// Code de billet lisible par un humain, par exemple `EH-7K2Q-M9XD`.
  ///
  /// Dérivé de l’id plutôt que stocké : l’id est déjà unique et immuable,
  /// donc le code n’exige aucune migration et ne peut pas diverger de lui.
  /// L’alphabet écarte `0/O` et `1/I/L` — ce code se lit à voix haute à une
  /// entrée, et ce sont précisément les caractères que l’on confond.
  String get ticketCode => ticketCodeFor(id);

  /// [ticketCode] de la réservation [id], sans la réservation elle-même :
  /// l’entrée confronte un code scanné à l’id qui l’accompagne avant de
  /// demander quoi que ce soit au serveur.
  static String ticketCodeFor(String id) {
    const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
    // FNV-1a, 32 bits, deux fois avec des offsets différents : stable d’une
    // exécution et d’une plateforme à l’autre, contrairement à
    // `String.hashCode`.
    int fnv(int seed) {
      var hash = seed;
      for (final unit in id.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
      return hash;
    }

    String chunk(int value) {
      final buffer = StringBuffer();
      var v = value;
      for (var i = 0; i < 4; i++) {
        buffer.write(alphabet[v % alphabet.length]);
        v ~/= alphabet.length;
      }
      return buffer.toString();
    }

    return 'EH-${chunk(fnv(0x811C9DC5))}-${chunk(fnv(0x050C5D1F))}';
  }

  /// Charge utile encodée dans le QR code du billet.
  String get ticketPayload => 'eventhub://ticket/$id?code=$ticketCode';

  bool get isActive => status == ReservationStatus.confirmed;
  bool get isPending => status == ReservationStatus.pending;
  bool get isCancelled => status == ReservationStatus.cancelled;

  /// Billet payé : l’annuler passe par un remboursement.
  bool get isPaid => pricePaid > 0;
  bool get isRefunded => paymentStatus == 'refunded';

  /// Ce à quoi le billet donne accès, tel qu’il est imprimé dessus.
  String get accessLabel =>
      (tierName?.isNotEmpty ?? false) ? tierName! : 'Accès général';
}
