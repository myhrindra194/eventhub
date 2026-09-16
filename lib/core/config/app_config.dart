import 'package:eventhub/core/config/flavor.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// Configuration d’exécution immuable, dérivée du [Flavor].
///
/// Il n’y a aucun backend simulé : chaque flavor parle au projet Firebase
/// décrit par `lib/firebase_options.dart`. Pour développer sur des données
/// jetables, démarrez les émulateurs (`make emulators`) et lancez avec
/// `--dart-define=USE_FIREBASE_EMULATOR=true`.
@immutable
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    this.useEmulator = const bool.fromEnvironment('USE_FIREBASE_EMULATOR'),
    this.emulatorHost = const String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: 'localhost',
    ),
    this.profileGracePeriod = const Duration(seconds: 3),
    this.googleServerClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    ),
    this.webPushVapidKey = const String.fromEnvironment(
      'FIREBASE_WEB_VAPID_KEY',
    ),
  });

  factory AppConfig.fromFlavor(Flavor flavor) => switch (flavor) {
    Flavor.dev => const AppConfig(
      flavor: Flavor.dev,
      appName: 'EventHub (dev)',
    ),
    Flavor.staging => const AppConfig(
      flavor: Flavor.staging,
      appName: 'EventHub (staging)',
    ),
    Flavor.prod => const AppConfig(flavor: Flavor.prod, appName: 'EventHub'),
  };

  final Flavor flavor;
  final String appName;

  /// Parler aux émulateurs locaux Auth (9099) et Firestore (8080) plutôt
  /// qu’au projet cloud. Ne jamais l’activer pour un build de release.
  final bool useEmulator;

  /// Hôte des émulateurs : `localhost` sur desktop, web et simulateur iOS ;
  /// `10.0.2.2` depuis l’émulateur Android ; l’adresse LAN de la machine
  /// depuis un téléphone physique.
  final String emulatorHost;

  /// Délai toléré entre la création d’un compte et celle de son document de
  /// profil avant que la session ne soit signalée comme `ProfileMissing`.
  final Duration profileGracePeriod;

  /// Client id OAuth *web* du projet Firebase, dont le Google Sign-In natif
  /// sur Android a besoin pour obtenir un ID token accepté par Firebase Auth
  /// (`--dart-define=GOOGLE_SERVER_CLIENT_ID=…apps.googleusercontent.com`).
  /// Vide → le bouton Google est masqué sur Android plutôt que d’échouer.
  final String googleServerClientId;

  /// Clé publique « Web Push certificate » du projet Firebase
  /// (`--dart-define=FIREBASE_WEB_VAPID_KEY=…`). Vide → aucun token push web.
  final String webPushVapidKey;

  /// Google Sign-In ne demande aucune configuration supplémentaire sur le
  /// web (popup Firebase) ni sur iOS (client id dans Info.plist) ; Android a
  /// besoin de [googleServerClientId]. Le desktop n’a pas de provider Google
  /// dans FlutterFire.
  bool get isGoogleSignInAvailable =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      (defaultTargetPlatform == TargetPlatform.android &&
          googleServerClientId.isNotEmpty);
}

/// Doit être surchargé dans `bootstrap()` ; l’implémentation par défaut lève
/// volontairement, pour qu’un oubli de surcharge soit détecté immédiatement
/// au lieu d’utiliser silencieusement la configuration dev.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) =>
    throw StateError('appConfigProvider must be overridden in bootstrap()');

/// Horloge injectable. À surcharger dans les tests pour figer le temps.
typedef Clock = DateTime Function();

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;
