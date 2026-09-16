import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation_dto.freezed.dart';
part 'reservation_dto.g.dart';

/// Document `reservations/{eventId}_{userId}`. L’id est lu depuis le
/// snapshot, pas depuis les champs.
///
/// En lecture seule : les seules écritures sont les transactions de
/// réservation et d’annulation de `ReservationRemoteDataSource`, dont les
/// listes de champs reproduisent exactement les `hasOnly([...])` de
/// `firebase/firestore.rules` ; il n’existe donc aucun chemin `toJson`
/// générique pour revenir vers la collection.
@Freezed(toJson: false)
abstract class ReservationDto with _$ReservationDto {
  const ReservationDto._();

  @JsonSerializable(createToJson: false)
  const factory ReservationDto({
    @Default('') String eventId,

    /// `''` une fois que le titulaire a supprimé son compte : le billet
    /// demeure, anonymisé, dans l’historique de l’organisateur.
    @Default('') String userId,
    @Default('') String organizerId,
    required String userName,
    required String userEmail,
    required String eventTitle,
    @TimestampConverter() required DateTime eventStartsAt,
    required String eventLocation,

    /// Un statut que ce build ne connaît pas n’est jamais lu comme une
    /// place valide.
    @JsonKey(unknownEnumValue: ReservationStatus.cancelled)
    required ReservationStatus status,

    /// Heure du client (les règles la bornent à l’horloge du serveur) :
    /// elle entre dans l’id de la notification de réservation, et n’est
    /// donc jamais une valeur serveur en attente.
    @TimestampConverter() required DateTime reservedAt,
    @NullableTimestampConverter() DateTime? cancelledAt,
    String? cancelledBy,
    String? tierId,
    String? tierName,
    @Default(0) int pricePaid,
  }) = _ReservationDto;

  factory ReservationDto.fromJson(Map<String, dynamic> json) =>
      _$ReservationDtoFromJson(json);

  Reservation toDomain(String id) => Reservation(
    id: id,
    eventId: eventId,
    userId: userId,
    organizerId: organizerId,
    userName: userName,
    userEmail: userEmail,
    eventTitle: eventTitle,
    eventStartsAt: eventStartsAt,
    eventLocation: eventLocation,
    status: status,
    reservedAt: reservedAt,
    cancelledAt: cancelledAt,
    cancelledBy: cancelledBy,
    tierId: tierId,
    tierName: tierName,
    pricePaid: pricePaid,
  );
}
