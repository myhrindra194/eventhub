import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

/// Document `users/{uid}/notifications/{id}`, écrit par celui qui a provoqué
/// le fait qu’il annonce (voir `validNotice()` dans
/// `firebase/firestore.rules`) et lu par son seul propriétaire.
///
/// `type` reste une simple chaîne : il porte les noms de [NotificationRoute],
/// et un type écrit par un build plus récent doit malgré tout s’afficher dans
/// un build plus ancien — il n’ouvre simplement rien.
@freezed
abstract class NotificationDto with _$NotificationDto {
  const NotificationDto._();

  const factory NotificationDto({
    @Default('') String type,
    @Default('') String title,
    @Default('') String body,
    String? eventId,
    String? reservationId,

    /// Heure serveur : `null` dans l’instantané local en attente côté auteur,
    /// et dans le premier instantané du destinataire lorsqu’il écoute en
    /// direct.
    @NullableTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? readAt,

    /// La politique de TTL sur ce champ supprime le document côté serveur ;
    /// le fil filtre aussi dessus, si bien qu’une notification expirée
    /// n’apparaît jamais dans la fenêtre entre sa date et le balayage.
    @NullableTimestampConverter() DateTime? expiresAt,
  }) = _NotificationDto;

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  AppNotification toDomain(String id) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    // Une notification tout juste écrite s’affiche immédiatement, datée de
    // maintenant, jusqu’à ce que l’heure serveur arrive un instant plus tard.
    createdAt: createdAt ?? DateTime.now(),
    eventId: eventId,
    reservationId: reservationId,
    readAt: readAt,
  );
}
