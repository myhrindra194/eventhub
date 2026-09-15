import 'dart:math';

import 'package:eventhub/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifier of this app installation, the `device_id` half of the
/// `devices` primary key `(user_id, device_id)`.
///
/// Why an installation id rather than one derived from the FCM token: a token
/// rotates (refresh, `deleteToken` on sign-out, restore on a new phone). Keyed
/// by the token, each rotation would leave the previous row behind until the
/// worker learns from FCM that it is dead; keyed by the installation, the
/// upsert in `public.register_device` replaces the token in place.
class DeviceIdStore {
  DeviceIdStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;
  String? _cached;

  static const storageKey = 'push.installationId';

  /// Returns the stored id, creating it on first use. If local storage is
  /// unavailable, falls back to an id derived from [token]: still stable for
  /// that token, which is all the server needs to upsert.
  Future<String> read({required String token}) async {
    if (_cached case final id?) return id;
    try {
      final prefs = await _preferences();
      final stored = prefs.getString(storageKey);
      if (stored != null && stored.isNotEmpty) return _cached = stored;
      final created = _randomId();
      await prefs.setString(storageKey, created);
      return _cached = created;
    } on Object catch (error) {
      AppLogger.warning('Installation id unavailable', error: error);
      return deviceIdFor(token);
    }
  }

  /// 128 random bits as 32 hex characters (the column accepts up to 128).
  static String _randomId() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  /// Stable id derived from the token, used only as a fallback.
  ///
  /// Two FNV-1a passes with different offsets give 64 bits without
  /// `dart:ffi`-only integer tricks, so the result is identical on the web.
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
