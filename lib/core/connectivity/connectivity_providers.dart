import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_providers.g.dart';

/// Indique si l’appareil a une interface réseau active.
///
/// « Active » ne veut pas dire « Firebase joignable » (un portail captif se
/// déclare en ligne) : c’est pourquoi ce provider ne pilote qu’un bandeau
/// informatif. Firestore, lui, continue de fonctionner depuis son cache et
/// rejoue les écritures au retour du lien.
@Riverpod(keepAlive: true)
Stream<bool> isOnline(Ref ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online).distinct();
}
