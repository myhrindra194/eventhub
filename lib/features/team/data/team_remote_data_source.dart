import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/features/team/data/staff_invitation_dto.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Co-organisateurs (F-16) : `events/{eventId}/invitations/{inviteeId}` et le
/// tableau `staffIds` de l’événement lui-même.
///
/// Il n’y a pas de code serveur sur le plan Spark : l’appartenance à l’équipe
/// n’est donc pas une table que le client fait modifier par une fonction. Une
/// invitation est un document que seul le propriétaire peut écrire, et
/// rejoindre l’équipe est une mise à jour de l’événement que les règles
/// n’acceptent **que** dans le lot qui marque aussi cette invitation comme
/// acceptée (`getAfter`). Un client qui n’écrit qu’une moitié de la paire est
/// refusé.
///
/// Conséquences à connaître :
///  * un invité est retrouvé par le hachage de son adresse dans
///    `organizerEmails`, un seul `get` sur une clé exacte — personne ne peut
///    énumérer les comptes ;
///  * les notifications qui suivent (invité, a rejoint, retiré) sont écrites
///    juste après le fait, au mieux : chacune est autorisée indépendamment par
///    l’état validé, et aucune ne doit faire échouer l’action qu’elle annonce.
class TeamRemoteDataSource {
  const TeamRemoteDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Une équipe compte au plus dix personnes ; la borne couvre les invitations
  /// déjà répondues laissées derrière eux par d’anciens membres.
  static const maxInvitations = 50;

  /// Les notifications in-app expirent (TTL sur `expiresAt`) au lieu de
  /// s’accumuler.
  static const noticeLifetime = Duration(days: 30);

  DocumentReference<Map<String, dynamic>> _event(String eventId) =>
      _db.collection(Collections.events).doc(eventId);

  CollectionReference<Map<String, dynamic>> _invitations(String eventId) =>
      _event(eventId).collection(Collections.invitations);

  CollectionReference<Map<String, dynamic>> _notifications(String userId) => _db
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.notifications);

  String get _uid => _auth.currentUser?.uid ?? '';

  // -------------------------------------------------------------- lectures

  /// Invitations en attente d’un événement, pour son équipe (index composite
  /// `status ASC, createdAt ASC`).
  Stream<List<StaffInvitation>> watchPendingForEvent(String eventId) =>
      _invitations(eventId)
          .where('status', isEqualTo: _pending)
          .orderBy('createdAt')
          .limit(maxInvitations)
          .snapshots()
          .map(_toList)
          .resilient('event-invitations');

  /// Les invitations adressées à [userId], tous événements confondus : une
  /// requête de groupe de collections, que les règles n’autorisent que si elle
  /// fixe `userId ==` à l’appelant (index `userId ASC, status ASC`).
  ///
  /// Le tri est côté client : ajouter `createdAt` à la requête exigerait un
  /// troisième index pour une liste qui ne dépasse jamais quelques entrées.
  Stream<List<StaffInvitation>> watchPendingForUser(String userId) => _db
      .collectionGroup(Collections.invitations)
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: _pending)
      .limit(maxInvitations)
      .snapshots()
      .map((query) => _toList(query)..sort(_oldestFirst))
      .resilient('my-invitations');

  static int _oldestFirst(StaffInvitation a, StaffInvitation b) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch);
  }

  // ------------------------------------------------------------ écritures

  /// Invite le compte organisateur enregistré sous [email].
  ///
  /// Tout refus sur lequel le propriétaire peut agir est décidé ici, avec sa
  /// phrase : les règles, elles, ne répondraient jamais que
  /// `permission-denied`.
  Future<void> invite({required String eventId, required String email}) async {
    final address = email.trim().toLowerCase();
    final inviteeId = await _lookUpOrganizer(address);
    if (inviteeId == _uid) throw const FailureException(_selfInvite);

    final eventSnapshot = await _event(eventId).get();
    final event = eventSnapshot.data();
    if (event == null) throw const FailureException(_eventGone);
    if (_staffIds(event).contains(inviteeId)) {
      throw const FailureException(_alreadyMember);
    }

    final ref = _invitations(eventId).doc(inviteeId);
    final existing = await ref.get();
    if (existing.exists) {
      if (existing.data()?['status'] == _pending) {
        throw const FailureException(_alreadyInvited);
      }
      // Une invitation refusée ou déjà répondue est un document que les règles
      // ne laisseraient personne mettre à jour : le propriétaire la supprime,
      // puis invite de nouveau — ce qui est exactement ce que réinviter veut
      // dire.
      await ref.delete();
    }

    // Le nom n’est montré à personne d’autre qu’à l’équipe ; la page publique
    // d’organisateur est le seul profil de l’invité que l’invitant peut lire.
    final invitee = await _db
        .collection(Collections.organizers)
        .doc(inviteeId)
        .get();

    await ref.set({
      'eventId': eventId,
      'userId': inviteeId,
      'email': address,
      'name': _clamp(invitee.data()?['name'] as String? ?? address, 80),
      'invitedBy': _uid,
      'invitedByName': _clamp(event['organizerName'] as String? ?? '', 80),
      // Copié tel quel : les règles comparent ce titre à celui de l’événement.
      'eventTitle': event['title'],
      'eventStartsAt': event['startsAt'],
      'status': _pending,
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });

    unawaited(
      _bestEffort(
        'staff invitation notice',
        () => _notifications(inviteeId)
            .doc(
              'staffInvite_${eventId}_${inviteeId}_'
              '${DateTime.now().millisecondsSinceEpoch}',
            )
            .set(
              _notice(
                type: 'staffInvite',
                title: 'Invitation à co-organiser',
                body:
                    '${event['organizerName']} vous invite à co-organiser '
                    '« ${event['title']} ».',
                eventId: eventId,
                actorId: _uid,
              ),
            ),
      ),
    );
  }

  /// `organizerEmails/{sha256(email)}` → l’uid, ou une phrase indiquant que
  /// l’adresse n’a pas d’espace organisateur (l’invité doit d’abord ouvrir le
  /// sien).
  Future<String> _lookUpOrganizer(String address) async {
    final lookup = await _db
        .collection(Collections.organizerEmails)
        .doc(DocIds.emailKey(address))
        .get();
    final uid = lookup.data()?['uid'] as String?;
    if (uid == null || uid.isEmpty) {
      throw const FailureException(
        NotFoundFailure(
          resource: Collections.organizerEmails,
          message:
              'Aucun espace organisateur à cette adresse. La personne doit '
              'créer son compte et activer « Devenir organisateur ».',
        ),
      );
    }
    return uid;
  }

  /// Accepte ou refuse l’invitation adressée à l’utilisateur connecté.
  ///
  /// Accepter tient en un seul lot : l’invitation passe à `accepted` et
  /// l’événement gagne le membre. Les règles lisent l’invitation *telle
  /// qu’elle sera* après le commit, si bien qu’aucune des deux moitiés ne peut
  /// voyager seule.
  Future<void> respond({required String eventId, required bool accept}) async {
    final uid = _uid;
    final ref = _invitations(eventId).doc(uid);
    final invitation = await ref.get();
    if (!invitation.exists || invitation.data()?['status'] != _pending) {
      throw const FailureException(_invitationGone);
    }

    final batch = _db.batch()
      ..update(ref, {
        'status': accept ? 'accepted' : 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    if (accept) {
      batch.update(_event(eventId), {
        'staffIds': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();
    if (!accept) return;

    final event = (await _event(eventId).get()).data();
    if (event == null) return;
    final owner = event['organizerId'] as String? ?? '';
    final name = invitation.data()?['name'] as String? ?? '';
    unawaited(
      _bestEffort(
        'staff joined notice',
        () => _notifications(owner)
            .doc('staffJoined_${eventId}_$uid')
            .set(
              _notice(
                type: 'staffJoined',
                title: 'Nouveau co-organisateur',
                body: '$name a rejoint l’équipe de « ${event['title']} ».',
                eventId: eventId,
                actorId: uid,
              ),
            ),
      ),
    );
  }

  /// Annule une invitation en attente, retire un membre ou quitte l’équipe —
  /// le même geste du point de vue de l’équipe, deux documents différents.
  Future<void> remove({required String eventId, required String userId}) async {
    final invitation = _invitations(eventId).doc(userId);
    final pending = await invitation.get();
    if (pending.exists && pending.data()?['status'] == _pending) {
      await invitation.delete();
      return;
    }

    await _event(eventId).update({
      'staffIds': FieldValue.arrayRemove([userId]),
    });

    final uid = _uid;
    if (userId == uid) return; // On quitte : personne à prévenir, sauf le log.
    final event = (await _event(eventId).get()).data();
    if (event == null) return;
    unawaited(
      _bestEffort(
        'staff removed notice',
        () => _notifications(userId)
            .doc(
              'staffRemoved_${eventId}_${userId}_'
              '${DateTime.now().millisecondsSinceEpoch}',
            )
            .set(
              _notice(
                type: 'staffRemoved',
                title: 'Vous ne co-organisez plus',
                body:
                    'Vous avez été retiré de l’équipe de '
                    '« ${event['title']} ».',
                eventId: eventId,
                actorId: uid,
              ),
            ),
      ),
    );
  }

  // ---------------------------------------------------------- utilitaires

  static const _pending = 'pending';

  static List<String> _staffIds(Map<String, dynamic> event) => [
    for (final id in event['staffIds'] as List<dynamic>? ?? const [])
      if (id is String) id,
  ];

  /// La liste exacte des champs de `validNotice()` dans les règles.
  static Map<String, Object?> _notice({
    required String type,
    required String title,
    required String body,
    required String eventId,
    required String actorId,
  }) => {
    'type': type,
    'title': _clamp(title, 120),
    'body': _clamp(body, 500),
    'eventId': eventId,
    'reservationId': null,
    'actorId': actorId,
    'createdAt': FieldValue.serverTimestamp(),
    'readAt': null,
    'expiresAt': Timestamp.fromDate(DateTime.now().add(noticeLifetime)),
  };

  static String _clamp(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max - 1)}…';

  /// Un effet de bord qui ne doit jamais faire échouer l’action qu’il suit.
  static Future<void> _bestEffort(
    String label,
    Future<void> Function() write,
  ) async {
    try {
      await write();
    } on Object catch (error) {
      AppLogger.warning('Best-effort write "$label" skipped', error: error);
    }
  }

  static List<StaffInvitation> _toList(
    QuerySnapshot<Map<String, dynamic>> query,
  ) => [for (final doc in query.docs) invitationFrom(doc.data())];

  static StaffInvitation invitationFrom(Map<String, dynamic> data) =>
      StaffInvitationDto.fromJson(data).toDomain();

  static const _selfInvite = ValidationFailure(
    message: 'C’est votre adresse : vous êtes déjà l’organisateur.',
  );

  static const _alreadyMember = BusinessRuleFailure(
    rule: BusinessRule.actionRefused,
    message: 'Cette personne fait déjà partie de l’équipe.',
  );

  static const _alreadyInvited = BusinessRuleFailure(
    rule: BusinessRule.actionRefused,
    message: 'Une invitation est déjà en attente pour cette adresse.',
  );

  static const _eventGone = NotFoundFailure(
    resource: 'event',
    message: 'Cet événement n’existe plus.',
  );

  static const _invitationGone = NotFoundFailure(
    resource: 'invitation',
    message: 'Cette invitation n’est plus disponible.',
  );
}
