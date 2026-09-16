import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// `reports/{targetType}_{targetId}_{reporterId}` et l’entrée de file de
/// modération qu’il alimente.
///
/// Les signalements sont en écriture seule pour leur auteur : seul un
/// administrateur les relit un jour. Les deux documents voyagent ensemble —
/// les règles n’acceptent un signalement que si l’entrée de file est ouverte
/// (ou son compteur déplacé) dans le même lot, et n’acceptent ce déplacement
/// que si le signalement de cet appelant y figure. Une personne, un
/// signalement, un incrément.
class ReportRemoteDataSource {
  const ReportRemoteDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Dépose le signalement, en ouvrant l’entrée de file ou en y comptant un
  /// signalement de plus.
  ///
  /// Impossible de lire au préalable lequel des deux cas s’applique :
  /// `moderationQueue` est fermée à tout le monde sauf à la modération, et
  /// c’est délibéré — savoir si une cible est déjà signalée est en soi une
  /// information. On tente donc d’abord le premier signalement, et le refus
  /// qui revient lorsque l’entrée existe déjà fait office de réponse : la
  /// seconde tentative compte au lieu d’ouvrir.
  ///
  /// Un second signalement par la *même* personne échoue dans les deux cas
  /// (son document de signalement existe déjà), ce que le repository traduit
  /// en [BusinessRule.alreadyReported].
  Future<void> create({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  }) async {
    try {
      await _commit(
        target: target,
        targetId: targetId,
        reason: reason,
        details: details,
        opening: true,
      );
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      await _commit(
        target: target,
        targetId: targetId,
        reason: reason,
        details: details,
        opening: false,
      );
    }
  }

  Future<void> _commit({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
    required bool opening,
  }) {
    final uid = _auth.currentUser?.uid ?? '';
    final entryId = DocIds.moderationEntry(target.name, targetId);
    final entry = _db.collection(Collections.moderationQueue).doc(entryId);
    final batch = _db.batch()
      ..set(
        _db
            .collection(Collections.reports)
            .doc(DocIds.report(target.name, targetId, uid)),
        {
          'targetType': target.name,
          'targetId': targetId,
          'reason': reason.wire,
          'details': details,
          'reporterId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

    if (opening) {
      batch.set(entry, {
        'targetType': target.name,
        'targetId': targetId,
        'reportCount': 1,
        'lastReason': reason.wire,
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // `update`, jamais `set` : une décision déjà consignée sur l’entrée doit
      // survivre à un nouveau signalement, et les règles refusent une écriture
      // qui la ferait disparaître.
      batch.update(entry, {
        'reportCount': FieldValue.increment(1),
        'lastReason': reason.wire,
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return batch.commit();
  }
}
