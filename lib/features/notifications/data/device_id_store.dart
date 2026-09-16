import 'dart:math';

import 'package:eventhub/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifiant de cette installation de l’application, la moitié `device_id`
/// de la clé primaire `(user_id, device_id)` de `devices`.
///
/// Pourquoi un identifiant d’installation plutôt qu’un identifiant dérivé du
/// jeton FCM : un jeton tourne (rafraîchissement, `deleteToken` à la
/// déconnexion, restauration sur un nouveau téléphone). Indexée sur le jeton,
/// chaque rotation laisserait la ligne précédente derrière elle jusqu’à ce que
/// le worker apprenne de FCM qu’elle est morte ; indexée sur l’installation,
/// l’upsert de `public.register_device` remplace le jeton sur place.
class DeviceIdStore {
  DeviceIdStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;
  String? _cached;

  static const storageKey = 'push.installationId';

  /// Renvoie l’identifiant stocké, en le créant à la première utilisation. Si
  /// le stockage local est indisponible, se rabat sur un identifiant dérivé de
  /// [token] : toujours stable pour ce jeton, ce qui suffit au serveur pour
  /// faire son upsert.
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

  /// 128 bits aléatoires en 32 caractères hexadécimaux (la colonne en accepte
  /// jusqu’à 128).
  static String _randomId() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  /// Identifiant stable dérivé du jeton, utilisé uniquement en repli.
  ///
  /// Deux passes FNV-1a avec des bases d’amorçage différentes donnent 64 bits
  /// sans recourir aux astuces sur entiers propres à `dart:ffi`, si bien que
  /// le résultat est identique sur le web.
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
