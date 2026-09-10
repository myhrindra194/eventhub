import '../../../events/domain/entities/event.dart';
import '../entities/reservation.dart';

class CreateReservationUseCase {
  Reservation call({required Event event, required int quantity}) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive.');
    }
    if (quantity > event.availablePlaces) {
      throw StateError('The requested quantity is not available.');
    }

    return Reservation(
      id: event.id,
      eventTitle: event.title,
      date: '${event.date} • ${event.time}',
      status: 'CONFIRMED',
      seatInfo: '$quantity x GENERAL ACCESS',
    );
  }
}
