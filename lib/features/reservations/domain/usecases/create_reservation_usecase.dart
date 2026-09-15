import '../../../events/domain/entities/event.dart';
import '../entities/reservation.dart';

class CreateReservationUseCase {
  Reservation call({required Event event, required int quantity}) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive.');
    }
    if (event.availablePlaces <= 0) {
      throw StateError('This event is sold out.');
    }
    if (quantity > event.availablePlaces) {
      throw StateError('The requested quantity is not available.');
    }

    return Reservation(
      id: '',
      eventId: event.id,
      eventTitle: event.title,
      date: '${event.displayDate} • ${event.time}',
      status: 'confirmed',
      seatInfo: '$quantity x GENERAL ACCESS',
      quantity: quantity,
    );
  }
}
