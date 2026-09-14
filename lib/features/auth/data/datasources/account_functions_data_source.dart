import 'package:cloud_functions/cloud_functions.dart';

/// Callable Cloud Functions acting on the signed-in account.
///
/// Errors surface as `FirebaseFunctionsException` carrying the French message
/// written on the server; `ErrorMapper` turns them into failures.
class AccountFunctionsDataSource {
  const AccountFunctionsDataSource(this._functions);

  final FirebaseFunctions _functions;

  /// See `deleteAccount` in `functions/src/index.ts` for the cascade.
  Future<void> deleteAccount() =>
      _functions.httpsCallable('deleteAccount').call<Object?>();
}
