import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation_dto.freezed.dart';
part 'reservation_dto.g.dart';

/// Firestore document `reservations/{eventId}_{userId}`.
///
/// Payment fields are omitted when null: the rules refuse a client write
/// that carries any of them (they belong to the payment functions).
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
    @JsonKey(includeIfNull: false) String? tierId,
    @JsonKey(includeIfNull: false) String? tierName,
    @Default(0) int pricePaid,
    @JsonKey(includeIfNull: false) int? amountDue,
    @JsonKey(includeIfNull: false) String? currency,
    @JsonKey(includeIfNull: false) String? paymentStatus,
    @JsonKey(includeIfNull: false) String? checkoutUrl,
    @JsonKey(includeIfNull: false)
    @NullableTimestampConverter()
    DateTime? holdExpiresAt,
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
    tierId: r.tierId,
    tierName: r.tierName,
    pricePaid: r.pricePaid,
    amountDue: r.amountDue,
    currency: r.currency,
    paymentStatus: r.paymentStatus,
    checkoutUrl: r.checkoutUrl,
    holdExpiresAt: r.holdExpiresAt,
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
    tierId: tierId,
    tierName: tierName,
    pricePaid: pricePaid,
    amountDue: amountDue,
    currency: currency,
    paymentStatus: paymentStatus,
    checkoutUrl: checkoutUrl,
    holdExpiresAt: holdExpiresAt,
  );
}
