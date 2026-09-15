import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'analytics_consent.g.dart';

/// The user's decision about audience measurement on this install.
///
/// `null` means "never asked": nothing is collected and the consent sheet is
/// offered once after sign-in. Stored locally because it is a device-level
/// choice (the same account on a shared tablet may decide differently).
/// Firebase Analytics is not exempt from consent under the CNIL guidelines,
/// hence opt-in rather than opt-out.
@Riverpod(keepAlive: true)
class AnalyticsConsent extends _$AnalyticsConsent {
  static const _key = 'analytics_consent_v1';

  @override
  Future<bool?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final granted = prefs.getBool(_key);
    // Collection is off by default (manifest / Info.plist); only an explicit
    // yes turns it on for this install.
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
