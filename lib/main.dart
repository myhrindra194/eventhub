import 'package:eventhub/bootstrap.dart';
import 'package:eventhub/core/config/flavor.dart';

/// Default entrypoint. Flavor comes from `--dart-define=FLAVOR=...`
/// (defaults to `dev`). See `main_dev.dart` / `main_prod.dart` for
/// IDE-friendly fixed entrypoints.
void main() => bootstrap(Flavor.fromEnvironment());
