import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// Firebase keeps what Supabase does not provide: push delivery (FCM),
/// crash reports and analytics. Data, auth, storage and server logic live in
/// Supabase (see `core/supabase`).
@Riverpod(keepAlive: true)
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;
