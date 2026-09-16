import 'dart:convert';

import 'package:eventhub/features/notifications/data/push_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Le client du Worker push n'a qu'une promesse à tenir : demander l'envoi
/// sans jamais gêner l'action qui l'a précédé. Ces tests vérifient le contrat
/// de l'appel, le « au mieux » et le plafond d'appels simultanés.
void main() {
  final endpoint = Uri.parse(
    'https://eventhub-api.example.workers.dev/v1/dispatch',
  );

  test('appelle le Worker avec l’ID token et la notification visée', () async {
    late http.Request sent;
    final dispatcher = WorkerPushDispatcher(
      client: MockClient((request) async {
        sent = request;
        return http.Response('{"status":"sent","delivered":1,"pruned":0}', 200);
      }),
      endpoint: endpoint,
      idToken: () async => 'id-token',
    );

    dispatcher.notify(
      recipientId: 'organizer-1',
      notificationId: 'booking_e1_p1_1',
    );
    await dispatcher.drain();

    expect(sent.method, 'POST');
    expect(sent.url, endpoint);
    expect(sent.headers['authorization'], 'Bearer id-token');
    expect(jsonDecode(sent.body), {
      'recipientId': 'organizer-1',
      'notificationId': 'booking_e1_p1_1',
    });
  });

  test('sans session, ne contacte pas le Worker', () async {
    var calls = 0;
    final dispatcher = WorkerPushDispatcher(
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
      endpoint: endpoint,
      idToken: () async => null,
    );
    dispatcher.notify(recipientId: 'u', notificationId: 'n');
    await dispatcher.drain();
    expect(calls, 0);
  });

  test('un refus ou une coupure réseau ne remonte jamais', () async {
    for (final client in [
      MockClient((_) async => http.Response('{"error":"not_the_actor"}', 403)),
      MockClient((_) => throw http.ClientException('offline')),
    ]) {
      final dispatcher = WorkerPushDispatcher(
        client: client,
        endpoint: endpoint,
        idToken: () async => 't',
      );
      dispatcher.notify(recipientId: 'u', notificationId: 'n');
      await expectLater(dispatcher.drain(), completes);
    }
  });

  test('limite les appels simultanés, puis vide toute la file', () async {
    var running = 0;
    var peak = 0;
    var done = 0;
    final dispatcher = WorkerPushDispatcher(
      client: MockClient((_) async {
        running++;
        peak = running > peak ? running : peak;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        running--;
        done++;
        return http.Response('{}', 200);
      }),
      endpoint: endpoint,
      idToken: () async => 't',
      maxConcurrent: 3,
    );

    // Une décision de modération : beaucoup de destinataires d'un coup.
    for (var i = 0; i < 20; i++) {
      dispatcher.notify(
        recipientId: 'holder-$i',
        notificationId: 'eventRemoved_a_$i',
      );
    }
    await dispatcher.drain();

    expect(done, 20);
    expect(peak, 3);
  });
}
