/// Build flavor, injected at compile time with `--dart-define=FLAVOR=<name>`.
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

  /// Resolves the flavor from `--dart-define`, defaulting to [dev].
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
