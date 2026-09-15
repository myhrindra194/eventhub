import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.reports` — insert-only for clients (no read access).
class ReportRemoteDataSource {
  const ReportRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Exactly the insertable columns: `reporter_id` defaults to `auth.uid()`
  /// and `created_at` is stamped by `reports_before_insert`, which also
  /// refuses reporting oneself and a missing target.
  Future<void> create({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  }) => _client.from(Tables.reports).insert({
    'target_type': target.name,
    'target_id': targetId,
    'reason': reason.wire,
    'details': details,
  });
}
