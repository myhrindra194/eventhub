import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/auth_dependencies.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/datasources/event_image_storage_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/get_organizer_events_usecase.dart';

final organizerEventRepositoryProvider = Provider<EventRepository>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    throw StateError('An authenticated organizer is required.');
  }
  return EventRepositoryImpl(
    EventRemoteDataSource(
      firestore: ref.watch(firestoreProvider),
      organizerId: user.uid,
    ),
    EventImageStorageDataSource(
      Supabase.instance.client,
      bucketName:
          dotenv.maybeGet('SUPABASE_EVENT_BUCKET') ??
          EventImageStorageDataSource.defaultBucketName,
    ),
  );
});

final getOrganizerEventsUseCaseProvider = Provider<GetOrganizerEventsUseCase>(
  (ref) =>
      GetOrganizerEventsUseCase(ref.watch(organizerEventRepositoryProvider)),
);

final organizerEventsProvider = FutureProvider<List<Event>>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    throw StateError('An authenticated organizer is required.');
  }

  final events = await ref.watch(getOrganizerEventsUseCaseProvider).call();
  return events.where((event) => event.organizerId == user.uid).toList();
});

final organizerEventDetailProvider = FutureProvider.family<Event?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(organizerEventRepositoryProvider);
  return repository.getEventById(id);
});
