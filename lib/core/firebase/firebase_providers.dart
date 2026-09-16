import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// Firebase constitue tout le backend sur le plan Spark : Authentication
/// pour les comptes, Cloud Firestore pour les données (protégé par
/// `firebase/firestore.rules`), FCM pour les tokens push, Crashlytics et
/// Analytics. Les data sources reçoivent les objets du SDK via ces providers
/// et ne touchent jamais aux singletons eux-mêmes, ce qui permet aux tests
/// de les surcharger.
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

@Riverpod(keepAlive: true)
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;

extension ResilientStream<T> on Stream<T> {
  /// Empêche un stream de snapshots de démolir un écran sur une erreur
  /// passagère (perte de réseau, listener révoqué pendant une déconnexion) :
  /// l’erreur est journalisée, et Firestore relance le listener de lui-même
  /// dès qu’il le peut.
  Stream<T> resilient(String label) => handleError((Object error) {
    AppLogger.warning('Snapshot stream "$label" interrupted', error: error);
  });
}
