import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/auth_dependencies.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/datasources/event_image_storage_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../../events/domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/get_organizer_events_usecase.dart';

/// Config Supabase centralisée : .env > --dart-define > bucket par défaut.
/// Évite de disperser dotenv.maybeGet / Supabase.instance dans les providers.
final supabaseEventBucketProvider = Provider<String>((ref) {
  const defined = String.fromEnvironment('SUPABASE_EVENT_BUCKET');
  final fromEnv = dotenv.maybeGet('SUPABASE_EVENT_BUCKET');
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  if (defined.isNotEmpty) return defined;
  return EventImageStorageDataSource.defaultBucketName;
});

final organizerEventRepositoryProvider = Provider<EventRepository>((ref) {
  // Réactif au login/logout : ref.watch(authProvider) rebuild quand la
  // session change, contrairement à FirebaseAuth.currentUser seul.
  final authState = ref.watch(authProvider);
  final user = authState.value;
  if (user == null) {
    throw StateError('An authenticated organizer is required.');
  }
  EventImageStorageDataSource imageStorage;
  try {
    imageStorage = EventImageStorageDataSource(
      Supabase.instance.client,
      bucketName: ref.watch(supabaseEventBucketProvider),
    );
  } catch (_) {
    // Supabase non initialisé (ex: .env absent en dev desktop) :
    // EventImageStorageNop lève une erreur explicite uniquement si un
    // upload est tenté. La lecture/gestion des événements reste dispo.
    imageStorage = EventImageStorageNop();
  }
  return EventRepositoryImpl(
    EventRemoteDataSource(
      firestore: ref.watch(firestoreProvider),
      organizerId: user.id,
    ),
    imageStorage,
  );
});

final getOrganizerEventsUseCaseProvider = Provider<GetOrganizerEventsUseCase>(
  (ref) =>
      GetOrganizerEventsUseCase(ref.watch(organizerEventRepositoryProvider)),
);

final organizerEventsProvider = FutureProvider<List<Event>>((ref) async {
  // Conservé pour compatibilité (ex: refresh ponctuel). Préférer
  // organizerEventsStreamProvider qui est temps réel.
  return ref.watch(getOrganizerEventsUseCaseProvider).call();
});

/// Stream temps réel : la UI se met à jour sans invalidate() manuel.
final organizerEventsStreamProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(organizerEventRepositoryProvider).watchEvents();
});

final organizerEventDetailProvider = FutureProvider.family<Event?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(organizerEventRepositoryProvider);
  return repository.getEventById(id);
});
