import 'package:eventhub/core/supabase/db.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Account operations that touch other people's data, run by the database.
class AccountRemoteDataSource {
  const AccountRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// `delete_my_account`: refused while an upcoming event of the caller has
  /// participants; otherwise seats released (paid ones refunded through the
  /// job queue), history anonymised, files queued, Auth user deleted — in
  /// one transaction.
  Future<void> deleteAccount() async {
    await _client.rpc<void>(Rpc.deleteMyAccount);
  }
}
