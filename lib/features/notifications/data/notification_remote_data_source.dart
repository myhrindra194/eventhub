import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/features/notifications/data/device_id_store.dart';
import 'package:eventhub/features/notifications/data/notification_dto.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';

/// Les trois sous-collections privées d’un compte :
/// `users/{uid}/notifications` (l’historique in-app),
/// `users/{uid}/private/notifications` (les préférences) et
/// `users/{uid}/devices` (les jetons FCM).
///
/// Tout ici est confiné à l’utilisateur connecté par les règles ; l’uid fait
/// malgré tout partie de chaque chemin, pour qu’un uid erroné donne une
/// lecture vide plutôt qu’un appui silencieux sur la politique de sécurité.
///
/// Sans Cloud Functions, rien ne tourne du côté de Google : « tout marquer
/// comme lu » est un lot d’écritures client, pas une instruction serveur —
/// voir [markAllRead].
class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._db, {DeviceIdStore? deviceIds})
    : _deviceIds = deviceIds ?? DeviceIdStore();

  final FirebaseFirestore _db;
  final DeviceIdStore _deviceIds;

  /// La politique de TTL conserve 30 jours ; un organisateur très actif peut
  /// tout de même en accumuler des centaines. L’écran affiche les plus
  /// récentes.
  static const maxNotifications = 100;

  /// Un lot Firestore contient au plus 500 écritures.
  static const maxBatchWrites = 450;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection(Collections.users).doc(uid);

  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _user(uid).collection(Collections.notifications);

  DocumentReference<Map<String, dynamic>> _preferences(String uid) => _user(
    uid,
  ).collection(Collections.private).doc(DocIds.notificationPreferences);

  // ------------------------------------------------------------ préférences

  /// Un document absent signifie « rien n’a jamais été modifié » : les valeurs
  /// par défaut s’appliquent, et c’est aussi ce que les règles autorisent la
  /// première écriture à créer.
  Stream<NotificationPreferences> watchPreferences(String uid) =>
      _preferences(uid)
          .snapshots()
          .map((s) => NotificationPreferences.fromMap(s.data()))
          .resilient('notification-preferences');

  /// `set` avec merge : le document est créé à la première modification puis
  /// mis à jour ensuite, sans lecture préalable pour distinguer les deux cas.
  /// Les règles acceptent exactement ces clés.
  Future<void> savePreferences(String uid, NotificationPreferences prefs) =>
      _preferences(uid).set({
        ...prefs.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ---------------------------------------------------------- notifications

  /// Les plus récentes d’abord, en nombre borné, entrées expirées exclues.
  ///
  /// L’ordre et la borne sont ceux de la requête — Firestore fait ce travail
  /// et le facture une fois ; il ne reste au client que le parsing et la
  /// fenêtre d’expiration, dont [notificationsFrom] se charge et que les tests
  /// couvrent.
  Stream<List<AppNotification>> watchNotifications(String uid) =>
      _notifications(uid)
          .orderBy('createdAt', descending: true)
          .limit(maxNotifications)
          .snapshots()
          .map(
            (query) => notificationsFrom([
              for (final d in query.docs) (d.id, d.data()),
            ]),
          )
          .resilient('notifications');

  /// `readAt` est le seul champ que les règles laissent le propriétaire
  /// modifier, une seule fois, avec l’horloge du serveur : celle du client
  /// n’entre pas en jeu, et une notification ne peut pas redevenir non lue.
  Future<void> markRead(String uid, String notificationId) => _notifications(
    uid,
  ).doc(notificationId).update({'readAt': FieldValue.serverTimestamp()});

  /// Marque comme lues toutes les notifications non lues.
  ///
  /// Faute d’instruction serveur à exécuter, les non lues sont relues puis
  /// écrites en un seul lot — y compris celles plus anciennes que le fil
  /// borné, parce que « tout marquer comme lu » veut dire toutes. Au-delà de
  /// [maxBatchWrites], le reste est laissé à l’appel suivant plutôt que de
  /// valider un lot que Firestore refuserait en bloc.
  Future<void> markAllRead(String uid) async {
    final unread = await _notifications(
      uid,
    ).where('readAt', isNull: true).limit(maxBatchWrites).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String uid, String notificationId) =>
      _notifications(uid).doc(notificationId).delete();

  /// Analyse les documents d’un instantané, dans leur ordre d’arrivée.
  ///
  /// Deux choses se passent ici plutôt que côté serveur. Une notification
  /// passé son `expiresAt` est masquée : la politique de TTL la supprime sous
  /// un jour environ, et personne ne devrait lire une notification périmée
  /// entre-temps. Et un document impossible à analyser est ignoré et
  /// journalisé plutôt que de faire échouer toute la liste, puisqu’un
  /// instantané porte toutes les entrées — une seule notification malformée
  /// viderait sinon l’écran.
  static List<AppNotification> notificationsFrom(
    List<(String id, Map<String, dynamic> data)> documents, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final notifications = <AppNotification>[];
    for (final (id, data) in documents) {
      try {
        final dto = NotificationDto.fromJson(data);
        if (dto.expiresAt?.isBefore(reference) ?? false) continue;
        notifications.add(dto.toDomain(id));
      } on Object catch (error) {
        AppLogger.warning('Malformed notification $id', error: error);
      }
    }
    return notifications;
  }

  // -------------------------------------------------------------- appareils

  /// Enregistre le jeton FCM [token] de cette installation sous le compte
  /// connecté.
  ///
  /// Le document est indexé sur l’installation, pas sur le jeton : un jeton
  /// tourne, et indexée sur le jeton chaque rotation laisserait une ligne
  /// morte derrière elle.
  ///
  /// Rien n’émet vers lui sur le plan Spark — un émetteur exige un serveur —
  /// mais le jeton est conservé pour qu’activer les Cloud Functions plus tard
  /// soit un déploiement, pas une migration.
  Future<void> registerDevice({
    required String uid,
    required String token,
    required String platform,
  }) async {
    await _user(uid)
        .collection(Collections.devices)
        .doc(await _deviceIds.read(token: token))
        .set({
          'token': token,
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
