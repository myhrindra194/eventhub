import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/features/auth/domain/entities/user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';

void main() {
  test('user exposes role helpers from the domain entity', () {
    const participant = User(
      id: 'user-1',
      email: 'user@example.com',
      name: 'Event User',
      role: UserRole.participant,
    );

    expect(participant.isParticipant, isTrue);
    expect(participant.isOrganizer, isFalse);
  });
}
