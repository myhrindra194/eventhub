import 'package:eventhub/features/checkin/domain/ticket_payload.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Résultat du scan d’un billet à l’entrée, du plus grave au moins grave.
enum CheckInStatus {
  /// Aucune réservation derrière ce QR.
  notFound,

  /// Un vrai billet, mais pour un autre événement.
  wrongEvent,

  /// Le code court ne correspond pas à l’id de réservation qui
  /// l’accompagne : le QR a été trafiqué.
  invalidCode,

  /// Une place payante encore retenue (F-11). Jamais produit sans serveur
  /// de paiement, conservé pour que l’entrée y soit prête.
  unpaid,

  /// Le participant a annulé : la place a été libérée.
  cancelled,

  /// Billet valide, déjà utilisé — la fraude la plus probable à une entrée
  /// (une capture d’écran partagée avec un ami).
  alreadyCheckedIn,

  /// On laisse entrer.
  admitted,
}

/// La réponse de l’entrée, et ce qu’elle peut dire du titulaire du billet.
///
/// Les champs du titulaire ne sont renseignés qu’une fois établi que le
/// billet appartient à l’événement scanné : un bénévole n’apprend jamais
/// rien sur les invités d’un autre événement.
class CheckInVerdict {
  const CheckInVerdict(
    this.status, {
    this.reservationId,
    this.holderName,
    this.tierName,
    this.checkedInAt,
  });

  final CheckInStatus status;
  final String? reservationId;
  final String? holderName;
  final String? tierName;

  /// Quand le billet a été scanné : maintenant pour
  /// [CheckInStatus.admitted], la première fois pour
  /// [CheckInStatus.alreadyCheckedIn].
  final DateTime? checkedInAt;

  bool get isAdmitted => status == CheckInStatus.admitted;

  /// Ce à quoi le billet donne accès, tel qu’il est imprimé dessus.
  String get accessLabel =>
      (tierName?.isNotEmpty ?? false) ? tierName! : 'Accès général';
}

/// Ce que l’entrée décide, en deux étapes pures.
///
/// L’admission elle-même est enregistrée par une transaction Firestore qui
/// lit la réservation et `events/{id}/checkins/{reservationId}`, et ne crée
/// ce dernier que s’il est absent. Le document de check-in est en ajout seul
/// dans les règles : deux entrées qui scannent le même billet au même
/// instant ne l’admettent donc jamais toutes les deux, la seconde
/// transaction rejoue, trouve l’entrée et répond
/// [CheckInStatus.alreadyCheckedIn].
abstract final class CheckInPolicy {
  /// `<eventId>_<userId>` (voir `DocIds.reservation`) : les ids automatiques
  /// de Firestore et les uid Firebase Auth sont tous deux `[A-Za-z0-9]`.
  static final _reservationId = RegExp(r'^[A-Za-z0-9]+_[A-Za-z0-9]+$');

  /// Un verdict que le scanner peut rendre sans le serveur, ou `null`
  /// lorsque le billet doit y être vérifié.
  ///
  /// * un id qui ne peut pas être un id de réservation n’est pas un billet ;
  /// * le code court est dérivé de l’id : un QR dont le code ne correspond
  ///   pas à son propre id est donc forgé — inutile de révéler si l’id
  ///   existe ;
  /// * l’id nomme son événement : un billet pour un autre événement est
  ///   refusé ici, ce qui importe d’autant plus que les règles ne
  ///   laisseraient même pas cette équipe lire la réservation d’un autre
  ///   événement.
  static CheckInVerdict? precheck({
    required String eventId,
    required String reservationId,
    required String code,
  }) {
    if (!_reservationId.hasMatch(reservationId)) {
      return const CheckInVerdict(CheckInStatus.notFound);
    }
    if (TicketPayload.normalizeCode(code) !=
        TicketPayload.normalizeCode(Reservation.ticketCodeFor(reservationId))) {
      return CheckInVerdict(
        CheckInStatus.invalidCode,
        reservationId: reservationId,
      );
    }
    final ticketEvent = reservationId.substring(
      0,
      reservationId.lastIndexOf('_'),
    );
    if (ticketEvent != eventId) {
      return CheckInVerdict(
        CheckInStatus.wrongEvent,
        reservationId: reservationId,
      );
    }
    return null;
  }

  /// Le verdict sur ce que la transaction de check-in a lu : la
  /// [reservation] (`null` quand elle n’existe pas) et l’existence
  /// éventuelle d’une entrée de check-in ([alreadyScanned], premier scan à
  /// [scannedAt]).
  static CheckInVerdict judge({
    required String eventId,
    required String reservationId,
    required Reservation? reservation,
    required bool alreadyScanned,
    required DateTime now,
    DateTime? scannedAt,
  }) {
    if (reservation == null) {
      return CheckInVerdict(
        CheckInStatus.notFound,
        reservationId: reservationId,
      );
    }
    if (reservation.eventId != eventId) {
      return CheckInVerdict(
        CheckInStatus.wrongEvent,
        reservationId: reservationId,
      );
    }
    CheckInVerdict verdict(CheckInStatus status, [DateTime? at]) =>
        CheckInVerdict(
          status,
          reservationId: reservationId,
          holderName: reservation.userName,
          tierName: reservation.tierName,
          checkedInAt: at,
        );
    if (reservation.isPending) return verdict(CheckInStatus.unpaid);
    if (!reservation.isActive) return verdict(CheckInStatus.cancelled);
    if (alreadyScanned) {
      return verdict(CheckInStatus.alreadyCheckedIn, scannedAt);
    }
    return verdict(CheckInStatus.admitted, now);
  }
}
