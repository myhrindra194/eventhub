import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final db = FirebaseFirestore.instance;
  final config = ref.watch(appConfigProvider);
  if (config.useFirebaseEmulators) {
    db.useFirestoreEmulator(config.emulatorHost, 8080);
  }
  return db;
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
