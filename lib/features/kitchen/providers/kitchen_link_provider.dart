import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/core/lan/kds_link.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';

enum KdsLinkStatus {
  /// Full POS with the LAN server up — kitchen devices can connect here.
  serving,

  /// KDS device with no till address configured yet.
  unconfigured,

  /// KDS device dialling the till (or the connection dropped — retrying).
  connecting,

  /// KDS device live-mirroring the till.
  connected,
}

class KitchenLinkState {
  final KdsLinkStatus status;

  /// Full mode: the address kitchen devices should dial (shown in Settings).
  final String serverAddress;

  /// KDS mode: the till address this device dials.
  final String tillAddress;
  final int clients;

  const KitchenLinkState({
    this.status = KdsLinkStatus.serving,
    this.serverAddress = '',
    this.tillAddress = '',
    this.clients = 0,
  });

  KitchenLinkState copyWith({
    KdsLinkStatus? status,
    String? serverAddress,
    String? tillAddress,
    int? clients,
  }) =>
      KitchenLinkState(
        status: status ?? this.status,
        serverAddress: serverAddress ?? this.serverAddress,
        tillAddress: tillAddress ?? this.tillAddress,
        clients: clients ?? this.clients,
      );
}

/// Runs the LAN side of the kitchen board, according to device mode:
///
/// - **Full POS** — hosts a [KdsServer]; every kitchen state change is
///   broadcast to connected displays, and their bump requests are applied to
///   the authoritative [kitchenProvider] here.
/// - **KDS** — connects a [KdsClient] to the configured till and mirrors its
///   snapshots into the local [kitchenProvider]; bumps are sent to the till,
///   never applied locally, so the two screens cannot diverge.
class KitchenLinkNotifier extends StateNotifier<KitchenLinkState> {
  KitchenLinkNotifier(this._ref, this._mode)
      : super(const KitchenLinkState()) {
    _start();
  }

  final Ref _ref;
  final DeviceMode _mode;

  KdsServer? _server;
  KdsClient? _client;
  StreamSubscription<List<KitchenOrder>>? _sub;

  Future<void> _start() async {
    if (_mode == DeviceMode.kds) {
      await _startClient();
    } else {
      await _startServer();
    }
  }

  // ── Till side ─────────────────────────────────────────────────────────────

  Future<void> _startServer() async {
    final server = KdsServer(
      getSnapshot: () =>
          [for (final o in _ref.read(kitchenProvider)) o.toJson()],
      onBump: (id) => _ref.read(kitchenProvider.notifier).bump(id),
    );
    try {
      await server.start();
    } catch (_) {
      // Port taken (another till on this machine?) — the local board still
      // works; only remote displays are unavailable.
      return;
    }
    if (!mounted) {
      await server.stop();
      return;
    }
    _server = server;
    _sub = _ref.read(kitchenProvider.notifier).stream.listen((orders) {
      server.broadcast([for (final o in orders) o.toJson()]);
      if (mounted) state = state.copyWith(clients: server.clientCount);
    });

    final ip = await _localIp();
    if (!mounted) return;
    state = state.copyWith(
      status: KdsLinkStatus.serving,
      serverAddress: '$ip:${KdsLink.defaultPort}',
    );
  }

  // ── Kitchen-display side ──────────────────────────────────────────────────

  static const _addressKey = 'kds_till_address';

  Future<void> _startClient() async {
    final addr =
        (await _ref.read(appDatabaseProvider).kvGet(_addressKey))?.trim() ?? '';
    if (!mounted) return;
    if (addr.isEmpty) {
      state = state.copyWith(status: KdsLinkStatus.unconfigured);
      return;
    }
    state =
        state.copyWith(status: KdsLinkStatus.connecting, tillAddress: addr);

    final client = KdsClient(
      address: addr,
      onSnapshot: (raw) {
        final orders = <KitchenOrder>[];
        for (final e in raw) {
          final o = KitchenOrder.tryFromJson(e);
          if (o != null) orders.add(o);
        }
        _ref.read(kitchenProvider.notifier).replaceAll(orders);
      },
      onStatus: (connected) {
        if (!mounted) return;
        state = state.copyWith(
          status:
              connected ? KdsLinkStatus.connected : KdsLinkStatus.connecting,
        );
      },
    );
    _client = client;
    unawaited(client.run());
  }

  /// Save a new till address (KDS device) and redial.
  Future<void> setTillAddress(String address) async {
    await _ref
        .read(appDatabaseProvider)
        .kvSet(_addressKey, address.trim());
    await _client?.close();
    _client = null;
    if (_mode == DeviceMode.kds && mounted) await _startClient();
  }

  /// Advance a ticket from whichever screen the user is on. On the till it is
  /// applied directly; on a KDS device it is a request to the till, whose
  /// rebroadcast updates this board.
  void bump(String id) {
    if (_mode == DeviceMode.kds) {
      _client?.bump(id);
    } else {
      _ref.read(kitchenProvider.notifier).bump(id);
    }
  }

  static Future<String> _localIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final i in interfaces) {
        for (final a in i.addresses) {
          return a.address;
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  @override
  void dispose() {
    _sub?.cancel();
    _server?.stop();
    _client?.close();
    super.dispose();
  }
}

final kitchenLinkProvider =
    StateNotifierProvider<KitchenLinkNotifier, KitchenLinkState>((ref) {
  // Rebuilds when the device mode flips, tearing down the old server/client.
  final mode = ref.watch(cloudSyncProvider.select((s) => s.deviceMode));
  return KitchenLinkNotifier(ref, mode);
});
