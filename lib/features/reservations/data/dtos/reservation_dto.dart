import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation_dto.freezed.dart';
part 'reservation_dto.g.dart';

/// Document `reservations/{eventId}_{userId}`. The id is read from the
/// snapshot, not from the fields.
///
/// Read-only: the only writes are the booking and cancellation transactions
/// of `ReservationRemoteDataSource`, whose field lists mirror the
/// `hasOnly([...])` of `firebase/firestore.rules` exactly, so there is no
/// generic `toJson` path back to the collection.
@Freezed(toJson: false)
abstract class ReservationDto with _$ReservationDto {
  const ReservationDto._();

  @JsonSerializable(createToJson: false)
  const factory ReservationDto({
    @Default('') String eventId,

    /// `''` once the holder deleted their account: the ticket stays,
    /// anonymised, in the organizer's history.
    @Default('') String userId,
    @Default('') String organizerId,
    required String userName,
    required String userEmail,
    required String eventTitle,
    @TimestampConverter() required DateTime eventStartsAt,
    required String eventLocation,

    /// A status this build does not know never reads as a valid seat.
    @JsonKey(unknownEnumValue: ReservationStatus.cancelled)
    required ReservationStatus status,

    /// Client time (the rules bound it to the server clock): it is part of
    /// the booking notification id, so it is never a pending server value.
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
