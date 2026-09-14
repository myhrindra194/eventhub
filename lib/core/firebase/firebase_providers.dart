import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// Firebase SDK singletons exposed through Riverpod so that data sources
/// never touch `.instance` directly (mockable in tests, emulator-aware).
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) {
  final auth = FirebaseAuth.instance;
  final config = ref.watch(appConfigProvider);
  if (config.useFirebaseEmulators) {
    auth.useAuthEmulator(config.emulatorHost, 9099);
  }
  return auth;
}

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) {
  final db = FirebaseFirestore.instance
    // Offline first: reads are served from the local cache when the network
    // drops, writes are queued and replayed. Bounded so a long-lived install
    // does not grow without limit.
    ..settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024,
    );
  final config = ref.watch(appConfigProvider);
  if (config.useFirebaseEmulators) {
    db.useFirestoreEmulator(config.emulatorHost, 8080);
  }
  return db;
}

@Riverpod(keepAlive: true)
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;

@Riverpod(keepAlive: true)
FirebaseFunctions firebaseFunctions(Ref ref) {
  final functions = FirebaseFunctions.instanceFor(
    region: AppConfig.functionsRegion,
  );
  final config = ref.watch(appConfigProvider);
  if (config.useFirebaseEmulators) {
    functions.useFunctionsEmulator(config.emulatorHost, 5001);
  }
  return functions;
}

@Riverpod(keepAlive: true)
FirebaseStorage firebaseStorage(Ref ref) {
  final storage = FirebaseStorage.instance;
  final config = ref.watch(appConfigProvider);
  if (config.useFirebaseEmulators) {
    storage.useStorageEmulator(config.emulatorHost, 9199);
  }
  return storage;
}
