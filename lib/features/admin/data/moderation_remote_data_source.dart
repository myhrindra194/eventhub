import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/admin/data/moderation_dtos.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Le back-office de modération : la file, les signalements derrière chaque
/// entrée, les décisions prises, et les décisions elles-mêmes.
///
/// Sur le plan Spark, il n’y a pas de fonction `moderate_content` à appeler :
/// une décision est un lot d’écritures client que les règles n’acceptent que
/// d’un administrateur (`admins/{uid}`, un document que seule la console
/// crée). Chaque décision se lit donc comme ce qu’elle fait — masquer cet avis
/// et déplacer cette note, annuler ces places et supprimer cet événement — et
/// chaque étape est prouvée indépendamment côté serveur.
class ModerationRemoteDataSource {
  const ModerationRemoteDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const pageSize = 100;
  static const decisionsPageSize = 50;

  /// Un lot Firestore contient au plus 500 écritures ; retirer un événement
  /// écrit une annulation et une notification par place.
  static const maxCancellations = 200;

  CollectionReference<Map<String, dynamic>> get _queue =>
      _db.collection(Collections.moderationQueue);

  String get _uid => _auth.currentUser?.uid ?? '';

  // -------------------------------------------------------------- lectures

  /// Entrées ouvertes, les plus signalées d’abord puis les plus récentes ;
  /// entrées fermées, les plus récemment décidées d’abord (index composites
  /// sur `status`).
  Stream<List<ModerationEntry>> watchQueue({required bool open}) {
    final query = open
        ? _queue
              .where('status', isEqualTo: 'open')
              .orderBy('reportCount', descending: true)
              .orderBy('updatedAt', descending: true)
        : _queue
              .where('status', whereIn: const ['resolved', 'dismissed'])
              .orderBy('updatedAt', descending: true);
    return query
        .limit(pageSize)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) ?entryFrom(doc.id, doc.data()),
          ],
        )
        .resilient(open ? 'moderation-queue-open' : 'moderation-queue-closed');
  }

  Stream<ModerationEntry?> watchEntry(String entryId) => _queue
      .doc(entryId)
      .snapshots()
      .map((s) => s.data() == null ? null : entryFrom(s.id, s.data()!))
      .resilient('moderation-entry');

  Stream<List<ReportRecord>> watchReports({
    required ReportTarget target,
    required String targetId,
  }) => _db
      .collection(Collections.reports)
      .where('targetType', isEqualTo: target.name)
      .where('targetId', isEqualTo: targetId)
      .orderBy('createdAt', descending: true)
      .limit(pageSize)
      .snapshots()
      .map((s) => [for (final doc in s.docs) reportFrom(doc.id, doc.data())])
      .resilient('moderation-reports');

  Stream<List<ModerationDecision>> watchDecisions(String entryId) => _queue
      .doc(entryId)
      .collection(Collections.decisions)
      .orderBy('at', descending: true)
      .limit(decisionsPageSize)
      .snapshots()
      .map(
        (s) => [
          for (final doc in s.docs)
            ModerationDecisionDto.fromJson(doc.data()).toDomain(),
        ],
      )
      .resilient('moderation-decisions');

  /// Le compte signalé, en incluant s’il est actuellement suspendu.
  Stream<ReportedAccount?> watchAccount(String userId) => _db
      .collection(Collections.users)
      .doc(userId)
      .snapshots()
      .map(
        (s) => s.data() == null
            ? null
            : ReportedAccountDto.fromFirestore(s.id, s.data()!).toDomain(),
      )
      .resilient('reported-account');

  /// Qui détient le rôle back-office. Seul un administrateur peut les lister.
  Stream<List<AdminAccount>> watchAdmins() => _db
      .collection(Collections.admins)
      .limit(pageSize)
      .snapshots()
      .map(
        (s) =>
            [
              for (final doc in s.docs)
                AdminAccountDto.fromFirestore(doc.id, doc.data()).toDomain(),
            ]..sort(
              (a, b) => (a.grantedAt ?? DateTime(0)).compareTo(
                b.grantedAt ?? DateTime(0),
              ),
            ),
      )
      .resilient('admins');

  // ------------------------------------------------------------- décisions

  /// Applique [action] à la cible de [entry] et la consigne.
  ///
  /// Renvoie le nombre de réservations annulées — retrait d’un événement
  /// uniquement.
  Future<int?> moderate({
    required ModerationEntry entry,
    required ModerationAction action,
    required String note,
  }) async {
    return switch (action) {
      ModerationAction.hide => _setReviewHidden(entry, note, hidden: true),
      ModerationAction.restore => _setReviewHidden(entry, note, hidden: false),
      ModerationAction.removeEvent => _removeEvent(entry, note),
      ModerationAction.suspend => _setSuspended(entry, note, suspended: true),
      ModerationAction.reinstate => _setSuspended(
        entry,
        note,
        suspended: false,
      ),
      ModerationAction.dismiss => _dismiss(entry, note),
    };
  }

  /// Masque ou rétablit un avis, en déplaçant la note de l’organisateur
  /// d’exactement ce que vaut cet avis — les règles n’acceptent le changement
  /// de note que dans le commit qui bascule `hidden`.
  Future<int?> _setReviewHidden(
    ModerationEntry entry,
    String note, {
    required bool hidden,
  }) async {
    final ref = _db.collection(Collections.reviews).doc(entry.targetId);
    final snapshot = await ref.get();
    final review = snapshot.data();
    if (review == null) throw const FailureException(_contentGone);
    if (review['hidden'] == hidden) throw const FailureException(_alreadyDone);

    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final organizerId = review['organizerId'] as String? ?? '';
    final step = hidden ? -1 : 1;

    final batch = _db.batch()
      ..update(ref, {'hidden': hidden})
      ..update(_db.collection(Collections.organizers).doc(organizerId), {
        'ratingSum': FieldValue.increment(rating * step),
        'ratingCount': FieldValue.increment(step),
        'lastReviewId': ref.id,
      });
    _close(
      batch,
      entry: entry,
      action: hidden ? ModerationAction.hide : ModerationAction.restore,
      note: note,
      status: 'resolved',
    );
    _tell(
      batch,
      userId: review['authorId'] as String? ?? '',
      type: hidden ? 'reviewHidden' : 'reviewRestored',
      title: hidden ? 'Votre avis a été masqué' : 'Votre avis est rétabli',
      body: hidden
          ? 'Après signalement, votre avis n’est plus visible. $note'.trim()
          : 'Après vérification, votre avis est de nouveau visible.',
      eventId: review['eventId'] as String? ?? '',
    );
    await batch.commit();
    return null;
  }

  /// Annule toutes les places confirmées, prévient chaque détenteur ainsi que
  /// l’organisateur, puis supprime l’événement.
  ///
  /// Les places ne sont pas rendues à l’événement : il est sur le point de
  /// disparaître. Ce qui lui survit, volontairement, ce sont les billets
  /// eux-mêmes — annulés, pour que chacun garde une trace de ce qu’il avait
  /// réservé.
  Future<int?> _removeEvent(ModerationEntry entry, String note) async {
    final eventRef = _db.collection(Collections.events).doc(entry.targetId);
    final event = (await eventRef.get()).data();
    if (event == null) throw const FailureException(_contentGone);

    final seats = await _db
        .collection(Collections.reservations)
        .where('eventId', isEqualTo: entry.targetId)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('reservedAt', descending: true)
        .limit(maxCancellations)
        .get();

    final title = event['title'] as String? ?? '';
    final batch = _db.batch();
    for (final seat in seats.docs) {
      batch.update(seat.reference, {
        'status': 'cancelled',
        'cancelledAt': Timestamp.now(),
        'cancelledBy': 'moderation',
      });
      _tell(
        batch,
        userId: seat.data()['userId'] as String? ?? '',
        type: 'eventRemoved',
        title: 'Événement retiré',
        body:
            '« $title » a été retiré après signalement. Votre réservation '
                    'est annulée. $note'
                .trim(),
        eventId: entry.targetId,
      );
    }
    _tell(
      batch,
      userId: event['organizerId'] as String? ?? '',
      type: 'eventRemoved',
      title: 'Votre événement a été retiré',
      body: '« $title » a été retiré par la modération. $note'.trim(),
      eventId: entry.targetId,
    );
    batch.delete(eventRef);
    _close(
      batch,
      entry: entry,
      action: ModerationAction.removeEvent,
      note: note,
      status: 'resolved',
    );
    await batch.commit();
    return seats.docs.length;
  }

  /// Suspend ou réactive un compte : le profil que les règles lisent à chaque
  /// écriture, et la page publique qui doit dire la même chose.
  Future<int?> _setSuspended(
    ModerationEntry entry,
    String note, {
    required bool suspended,
  }) async {
    final userRef = _db.collection(Collections.users).doc(entry.targetId);
    final user = (await userRef.get()).data();
    if (user == null) throw const FailureException(_contentGone);
    if ((user['suspended'] as bool? ?? false) == suspended) {
      throw const FailureException(_alreadyDone);
    }

    final page = _db.collection(Collections.organizers).doc(entry.targetId);
    final hasPage = (await page.get()).exists;

    final batch = _db.batch()..update(userRef, {'suspended': suspended});
    if (hasPage) batch.update(page, {'suspended': suspended});
    _tell(
      batch,
      userId: entry.targetId,
      type: suspended ? 'accountSuspended' : 'accountReinstated',
      title: suspended ? 'Compte suspendu' : 'Compte réactivé',
      body: suspended
          ? 'Votre compte est suspendu par la modération. $note'.trim()
          : 'Votre compte est de nouveau actif.',
      eventId: null,
    );
    _close(
      batch,
      entry: entry,
      action: suspended ? ModerationAction.suspend : ModerationAction.reinstate,
      note: note,
      status: 'resolved',
    );
    await batch.commit();
    return null;
  }

  Future<int?> _dismiss(ModerationEntry entry, String note) async {
    final batch = _db.batch();
    _close(
      batch,
      entry: entry,
      action: ModerationAction.dismiss,
      note: note,
      status: 'dismissed',
    );
    await batch.commit();
    return null;
  }

  /// Appose la décision sur l’entrée de file et l’ajoute à l’historique.
  void _close(
    WriteBatch batch, {
    required ModerationEntry entry,
    required ModerationAction action,
    required String note,
    required String status,
  }) {
    final ref = _queue.doc(entry.id);
    batch
      ..update(ref, {
        'status': status,
        'decision': action.wire,
        'decisionNote': note,
        'decidedBy': _uid,
        'decidedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(ref.collection(Collections.decisions).doc(), {
        'action': action.wire,
        'note': note,
        'by': _uid,
        'at': FieldValue.serverTimestamp(),
      });
  }

  /// Une notification de modération à la personne concernée. Une décision dont
  /// personne n’est informé est une décision que personne ne peut contester.
  void _tell(
    WriteBatch batch, {
    required String userId,
    required String type,
    required String title,
    required String body,
    required String? eventId,
  }) {
    if (userId.isEmpty) return;
    batch.set(
      _db
          .collection(Collections.users)
          .doc(userId)
          .collection(Collections.notifications)
          .doc('${type}_${_uid}_${DateTime.now().millisecondsSinceEpoch}'),
      {
        'type': type,
        'title': _clamp(title, 120),
        'body': _clamp(body, 500),
        'eventId': eventId,
        'reservationId': null,
        'actorId': _uid,
        'createdAt': FieldValue.serverTimestamp(),
        'readAt': null,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      },
    );
  }

  static String _clamp(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max - 1)}…';

  static ModerationEntry? entryFrom(String id, Map<String, dynamic> data) =>
      ModerationEntryDto.fromFirestore(id, data).toDomain();

  static ReportRecord reportFrom(String id, Map<String, dynamic> data) =>
      ReportRecordDto.fromFirestore(id, data).toDomain();

  static const _contentGone = NotFoundFailure(
    resource: 'content',
    message: 'Ce contenu n’existe plus : le dossier peut être classé.',
  );

  static const _alreadyDone = BusinessRuleFailure(
    rule: BusinessRule.actionRefused,
    message: 'C’est déjà l’état actuel de ce contenu.',
  );
}
