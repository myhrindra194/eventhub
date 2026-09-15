import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// Firebase is the whole backend on the Spark plan: Authentication for
/// accounts, Cloud Firestore for data (protected by `firebase/firestore.rules`),
/// FCM for push tokens, Crashlytics and Analytics. Data sources receive the
/// SDK objects through these providers and never touch the singletons
/// themselves, so tests can override them.
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

@Riverpod(keepAlive: true)
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;

extension ResilientStream<T> on Stream<T> {
  /// Keeps a snapshot stream from tearing a screen down on a transient error
  /// (network loss, a listener revoked while signing out): the error is
  /// logged, and Firestore resumes the listener by itself when it can.
  Stream<T> resilient(String label) => handleError((Object error) {
    AppLogger.warning('Snapshot stream "$label" interrupted', error: error);
  });
}
