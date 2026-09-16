import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/features/notifications/data/push_dispatcher.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_dispatcher_provider.g.dart';

/// Le porte-voix FCM partagé par tous les écrivains de notifications
/// (réservations, équipe, modération).
///
/// Dans un fichier à part plutôt que dans `notification_providers.dart` :
/// ces trois features en dépendent, et les faire importer tout le centre de
/// notifications créerait des cycles d'import entre features.
@Riverpod(keepAlive: true)
PushDispatcher pushDispatcher(Ref ref) {
  final url = ref.watch(appConfigProvider).apiWorkerUrl;
  if (url.isEmpty) return const NoPushDispatcher();

  final client = http.Client();
  ref.onDispose(client.close);
  final auth = ref.watch(firebaseAuthProvider);
  return WorkerPushDispatcher(
    client: client,
    endpoint: Uri.parse(url).resolve('/v1/dispatch'),
    // Jeton lu à chaque envoi : le SDK le renouvelle lui-même avant
    // expiration, et un compte déconnecté entre-temps n'envoie rien.
    idToken: () async => auth.currentUser?.getIdToken(),
  );
}
