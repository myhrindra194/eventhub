/// Flavor de build, injecté à la compilation par `--dart-define=FLAVOR=<name>`.
///
/// ```sh
/// flutter run --dart-define=FLAVOR=dev
/// flutter build apk --dart-define=FLAVOR=prod
/// ```
enum Flavor {
  dev,
  staging,
  prod;

  static const _envKey = 'FLAVOR';

  /// Résout le flavor depuis `--dart-define`, avec [dev] par défaut.
  static Flavor fromEnvironment() {
    const raw = String.fromEnvironment(_envKey, defaultValue: 'dev');
    return Flavor.values.firstWhere(
      (f) => f.name == raw,
      orElse: () => throw StateError('Unknown FLAVOR "$raw"'),
    );
  }

  bool get isDev => this == Flavor.dev;
  bool get isProd => this == Flavor.prod;
}
