import 'package:eventhub/bootstrap.dart';
import 'package:eventhub/core/config/flavor.dart';

/// Point d'entrée par défaut. Le flavor vient de `--dart-define=FLAVOR=…`
/// et vaut `dev` à défaut. Voir `main_dev.dart` / `main_prod.dart` pour les
/// points d'entrée fixes, plus commodes depuis un IDE.
void main() => bootstrap(Flavor.fromEnvironment());
