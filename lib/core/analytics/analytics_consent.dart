import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'analytics_consent.g.dart';

/// La décision de l’utilisateur sur la mesure d’audience, pour cette
/// installation.
///
/// `null` signifie « jamais demandé » : rien n’est collecté et la feuille de
/// consentement est proposée une fois après la connexion. Le choix est
/// stocké localement parce qu’il relève de l’appareil (le même compte sur
/// une tablette partagée peut trancher autrement). Firebase Analytics n’est
/// pas exempté de consentement au regard des lignes directrices de la CNIL,
/// d’où un opt-in plutôt qu’un opt-out.
@Riverpod(keepAlive: true)
class AnalyticsConsent extends _$AnalyticsConsent {
  static const _key = 'analytics_consent_v1';

  @override
  Future<bool?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final granted = prefs.getBool(_key);
    // La collecte est désactivée par défaut (manifest / Info.plist) ; seul
    // un oui explicite l’active pour cette installation.
    await ref.read(appAnalyticsProvider).setCollectionEnabled(granted ?? false);
    return granted;
  }

  Future<void> set(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, granted);
    state = AsyncData(granted);
    await ref.read(appAnalyticsProvider).setCollectionEnabled(granted);
  }
}
