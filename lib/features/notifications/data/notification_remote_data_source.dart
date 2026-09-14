import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';

/// Firestore access for `users/{uid}/devices/*` and
/// `users/{uid}/private/notifications`.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource(FirebaseFirestore firestore)
    : _users = firestore.collection(FirestorePaths.users);

  final CollectionReference<Map<String, dynamic>> _users;

  DocumentReference<Map<String, dynamic>> _preferences(String uid) => _users
      .doc(uid)
      .collection(FirestorePaths.private)
      .doc(FirestorePaths.notificationPreferencesDoc);

  Stream<NotificationPreferences> watchPreferences(String uid) => _preferences(
    uid,
  ).snapshots().map((s) => NotificationPreferences.fromMap(s.data()));

  Future<void> savePreferences(String uid, NotificationPreferences prefs) =>
      _preferences(
        uid,
      ).set({...prefs.toMap(), 'updatedAt': FieldValue.serverTimestamp()});

  /// Bounded: the TTL keeps 30 days, a very active organizer can still
  /// accumulate hundreds; the screen shows the most recent ones.
  static const maxNotifications = 100;

  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _users.doc(uid).collection(FirestorePaths.notifications);

  Stream<List<AppNotification>> watchNotifications(String uid) =>
      _notifications(uid)
          .orderBy('createdAt', descending: true)
          .limit(maxNotifications)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((d) => notificationFromFirestore(d.id, d.data()))
                .toList(growable: false),
          );

  /// `readAt` is the only field the rules let the owner change.
  Future<void> markRead(String uid, String notificationId) => _notifications(
    uid,
  ).doc(notificationId).update({'readAt': FieldValue.serverTimestamp()});

  Future<void> markAllRead(String uid, List<String> ids) async {
    if (ids.isEmpty) return;
    // A batch holds 500 writes; the list is capped at [maxNotifications].
    final batch = _users.firestore.batch();
    for (final id in ids) {
      batch.update(_notifications(uid).doc(id), {
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String uid, String notificationId) =>
      _notifications(uid).doc(notificationId).delete();

  /// Tolerant parser: a document written by an older function version, or a
  /// server timestamp not resolved yet, still renders.
  static AppNotification notificationFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    String? text(String key) =>
        data[key] is String ? data[key] as String : null;
    DateTime? time(String key) => switch (data[key]) {
      final Timestamp t => t.toDate(),
      _ => null,
    };
    return AppNotification(
      id: id,
      type: text('type') ?? 'unknown',
      title: text('title') ?? '',
      body: text('body') ?? '',
      createdAt: time('createdAt') ?? DateTime.now(),
      eventId: text('eventId'),
      reservationId: text('reservationId'),
      readAt: time('readAt'),
    );
  }

  /// The field set is exactly what `firestore.rules` accepts on
  /// `devices/{deviceId}`: token, platform, locale, updatedAt (server time).
  Future<void> registerDevice({
    required String uid,
    required String token,
    required String platform,
  }) {
    return _users
        .doc(uid)
        .collection(FirestorePaths.devices)
        .doc(deviceIdFor(token))
        .set({
          'token': token,
          'platform': platform,
          'locale': 'fr_FR',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Stable document id derived from the token.
  ///
  /// The token itself is not used as id: it is long, and a document id is
  /// part of every path the Cloud Functions log. Two FNV-1a passes with
  /// different offsets give 64 bits without `dart:ffi`-only integer tricks,
  /// so the result is identical on the web.
  static String deviceIdFor(String token) {
    int fnv(int seed) {
      var hash = seed;
      for (final unit in token.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
      return hash;
    }

    String hex(int v) => v.toRadixString(16).padLeft(8, '0');
    return '${hex(fnv(0x811C9DC5))}${hex(fnv(0x050C5D1F))}';
  }
}
