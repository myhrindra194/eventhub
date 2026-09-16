import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/checkin/data/check_in_remote_data_source.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/checkin/domain/check_in_repository.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  const CheckInRepositoryImpl(this._remote);

  final CheckInRemoteDataSource _remote;

  @override
  Stream<Map<String, DateTime>> watchCheckIns(String eventId) =>
      _remote.watchCheckIns(eventId);

  @override
  AsyncResult<CheckInVerdict> checkIn({
    required String eventId,
    required String reservationId,
    required String scannedBy,
  }) => guard(
    () => _remote.checkIn(
      eventId: eventId,
      reservationId: reservationId,
      scannedBy: scannedBy,
    ),
  );
}
