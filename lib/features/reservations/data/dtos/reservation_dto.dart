import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation_dto.freezed.dart';
part 'reservation_dto.g.dart';

/// Row of `public.reservations`, as returned by PostgREST, Realtime and the
/// `reserve_seat` / `cancel_reservation` functions.
///
/// Read-only: every write goes through a database function or a payment
/// Edge Function, so there is no `toJson` path back to the table. Internal
/// payment columns (`checkout_session_id`, `payment_intent_id`, `refund_id`,
/// `reminder_sent_at`) are ignored — the app never acts on them.
@Freezed(toJson: false)
abstract class ReservationDto with _$ReservationDto {
  const ReservationDto._();

  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ReservationDto({
    required String id,

    /// The three references become null when the event or an account is
    /// deleted; the snapshot columns stay.
    String? eventId,
    String? userId,
    String? organizerId,
    required String userName,
    required String userEmail,
    required String eventTitle,
    @TimestampConverter() required DateTime eventStartsAt,
    required String eventLocation,
    @JsonKey(unknownEnumValue: ReservationStatus.cancelled)
    required ReservationStatus status,
    @TimestampConverter() required DateTime reservedAt,
    @NullableTimestampConverter() DateTime? cancelledAt,
    String? tierId,
    String? tierName,
    @Default(0) int pricePaid,
    int? amountDue,
    String? currency,
    String? paymentStatus,
    String? checkoutUrl,
    @NullableTimestampConverter() DateTime? holdExpiresAt,
  }) = _ReservationDto;

  factory ReservationDto.fromJson(Map<String, dynamic> json) =>
      _$ReservationDtoFromJson(json);

  Reservation toDomain() => Reservation(
    id: id,
    eventId: eventId ?? '',
    userId: userId ?? '',
    organizerId: organizerId ?? '',
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
