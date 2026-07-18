import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:easycasher/core/lan/kds_link.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';

/// The LAN kitchen link: the till serves the board over a websocket, kitchen
/// displays mirror it and send bump *requests* back. These run the real
/// server and client against each other over loopback — no mocks.
void main() {
  KitchenOrder ticket({
    String id = 'k1',
    KotStatus status = KotStatus.pending,
    KotOrderType type = KotOrderType.dineIn,
  }) =>
      KitchenOrder(
        id: id,
        kotNumber: 1,
        tableId: 'T1',
        tableLabel: 'Table 1',
        items: const [
          KotItem(name: 'Burger', quantity: 2, unitPrice: 2500,
              modifierSummary: 'No onion'),
        ],
        status: status,
        orderType: type,
        createdAt: DateTime(2026, 7, 18, 12, 0),
      );

  /// Wait until [done] holds, or fail loudly — never hang the suite.
  Future<void> until(bool Function() done,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final deadline = DateTime.now().add(timeout);
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition not reached within $timeout');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  group('ticket serialization', () {
    test('a ticket survives the wire round-trip intact', () {
      final t = ticket(status: KotStatus.inProgress, type: KotOrderType.delivery);
      final back = KitchenOrder.tryFromJson(t.toJson())!;

      expect(back.id, t.id);
      expect(back.status, KotStatus.inProgress);
      expect(back.orderType, KotOrderType.delivery);
      expect(back.tableLabel, 'Table 1');
      expect(back.items.single.name, 'Burger');
      expect(back.items.single.quantity, 2);
      expect(back.items.single.modifierSummary, 'No onion');
      expect(back.total, 5000);
    });

    test('junk from a mismatched version is skipped, not fatal', () {
      expect(KitchenOrder.tryFromJson(null), isNull);
      expect(KitchenOrder.tryFromJson('nonsense'), isNull);
      expect(KitchenOrder.tryFromJson(<String, dynamic>{}), isNull);
      // Unknown enum names fall back rather than throw.
      final odd = KitchenOrder.tryFromJson({
        'id': 'x',
        'status': 'flambéed',
        'orderType': 'drone',
      })!;
      expect(odd.status, KotStatus.pending);
      expect(odd.orderType, KotOrderType.dineIn);
    });
  });

  group('server <-> client over loopback', () {
    test('snapshot on connect, broadcast on change, bump flows back', () async {
      var board = <KitchenOrder>[ticket()];
      final bumped = <String>[];

      final server = KdsServer(
        getSnapshot: () => [for (final o in board) o.toJson()],
        onBump: bumped.add,
      );
      // Ephemeral port + loopback: no clash, no firewall prompt in tests.
      await server.start(port: 0, bind: InternetAddress.loopbackIPv4);

      final snapshots = <List<dynamic>>[];
      var connected = false;
      final client = KdsClient(
        address: '127.0.0.1:${server.port}',
        onSnapshot: snapshots.add,
        onStatus: (c) => connected = c,
        retryDelay: const Duration(milliseconds: 100),
      );
      unawaited(client.run());

      // 1. Connecting delivers the current board immediately.
      await until(() => connected && snapshots.isNotEmpty);
      expect(server.clientCount, 1);
      final first = KitchenOrder.tryFromJson(snapshots.first.single)!;
      expect(first.id, 'k1');
      expect(first.status, KotStatus.pending);

      // 2. The kitchen bumps — the request reaches the till, which applies it
      //    and rebroadcasts the new truth.
      client.bump('k1');
      await until(() => bumped.contains('k1'));
      board = [ticket(status: KotStatus.inProgress)];
      server.broadcast([for (final o in board) o.toJson()]);
      await until(() => snapshots.length >= 2);
      final updated = KitchenOrder.tryFromJson(snapshots.last.single)!;
      expect(updated.status, KotStatus.inProgress);

      await client.close();
      await server.stop();
    });

    test('a display reconnects by itself after the till restarts', () async {
      final server1 = KdsServer(getSnapshot: () => [], onBump: (_) {});
      await server1.start(port: 0, bind: InternetAddress.loopbackIPv4);
      final port = server1.port!;

      var connects = 0;
      final client = KdsClient(
        address: '127.0.0.1:$port',
        onSnapshot: (_) {},
        onStatus: (c) {
          if (c) connects++;
        },
        retryDelay: const Duration(milliseconds: 100),
      );
      unawaited(client.run());
      await until(() => connects == 1);

      // Till goes down mid-service…
      await server1.stop();
      await until(() => !client.isConnected);

      // …and comes back on the same address. The display must find it alone.
      final server2 = KdsServer(
        getSnapshot: () => [ticket(id: 'k2').toJson()],
        onBump: (_) {},
      );
      await server2.start(port: port, bind: InternetAddress.loopbackIPv4);
      await until(() => connects == 2);

      await client.close();
      await server2.stop();
    });
  });
}
