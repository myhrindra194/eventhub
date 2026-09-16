import 'package:firebase_messaging/firebase_messaging.dart';

/// Appelée par FCM dans un isolate d’arrière-plan quand un message arrive
/// alors que l’application n’est pas au premier plan.
///
/// Chaque message envoyé par l’Edge Function `worker` porte un bloc
/// `notification`, qu’Android et iOS affichent eux-mêmes dans cet état — il
/// n’y a donc rien à rendre ici. Le handler doit malgré tout exister et être
/// enregistré (voir `bootstrap.dart`), sans quoi les messages data-only sont
/// perdus.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Enveloppe mince autour de [FirebaseMessaging], pour que la couche
/// application soit testable sans le plugin.
class PushMessagingDataSource {
  const PushMessagingDataSource(this._messaging);

  final FirebaseMessaging _messaging;

  /// Affiche l’invite système (Android 13+, iOS) une seule fois ; ensuite,
  /// renvoie la décision mémorisée sans redemander.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently ||
      AuthorizationStatus.notDetermined => false,
    };
  }

  /// [vapidKey] est obligatoire sur le web, ignorée ailleurs.
  Future<String?> getToken({String? vapidKey}) =>
      _messaging.getToken(vapidKey: vapidKey);

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Messages reçus pendant que l’application est au premier plan (non
  /// affichés par le système).
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Une notification touchée alors que l’application était en arrière-plan.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// La notification qui a lancé l’application depuis un état terminé, s’il y
  /// en a une.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  /// Invalide le jeton de cet appareil. Appelée à la déconnexion pour que la
  /// personne suivante à se connecter sur le même téléphone ne reçoive jamais
  /// les pushs de l’utilisateur précédent : le prochain envoi vers l’ancien
  /// jeton se voit répondre `UNREGISTERED` et le worker supprime la ligne
  /// périmée de `devices` (`devices_forget_tokens`).
  Future<void> deleteToken() => _messaging.deleteToken();
}
