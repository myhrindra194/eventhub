import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation_dto.freezed.dart';
part 'reservation_dto.g.dart';

/// Firestore document `reservations/{eventId}_{userId}`.
@freezed
abstract class ReservationDto with _$ReservationDto {
  const ReservationDto._();

  const factory ReservationDto({
    required String eventId,
    required String userId,
    required String organizerId,
    required String userName,
    required String userEmail,
    required String eventTitle,
    @TimestampConverter() required DateTime eventStartsAt,
    required String eventLocation,
    @JsonKey(unknownEnumValue: ReservationStatus.cancelled)
    required ReservationStatus status,
    @TimestampConverter() required DateTime reservedAt,
    @NullableTimestampConverter() DateTime? cancelledAt,
  }) = _ReservationDto;

  factory ReservationDto.fromJson(Map<String, dynamic> json) =>
      _$ReservationDtoFromJson(json);

  factory ReservationDto.fromDomain(Reservation r) => ReservationDto(
    eventId: r.eventId,
    userId: r.userId,
    organizerId: r.organizerId,
    userName: r.userName,
    userEmail: r.userEmail,
    eventTitle: r.eventTitle,
    eventStartsAt: r.eventStartsAt,
    eventLocation: r.eventLocation,
    status: r.status,
    reservedAt: r.reservedAt,
    cancelledAt: r.cancelledAt,
  );

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
  );
}
