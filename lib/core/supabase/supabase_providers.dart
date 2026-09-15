import 'package:eventhub/core/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_providers.g.dart';

/// The Supabase client, initialised in `bootstrap()`. Data sources receive it
/// through this provider and never touch `Supabase.instance` themselves, so
/// tests can override it.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

extension ResilientStream<T> on Stream<T> {
  /// Keeps a Realtime stream alive across transient channel errors (network
  /// loss, phone asleep): the client resubscribes by itself, so an error is
  /// logged rather than tearing down the screen listening to it.
  Stream<T> resilient(String label) => handleError((Object error) {
    AppLogger.warning('Realtime stream "$label" interrupted', error: error);
  });
}
