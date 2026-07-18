import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The LAN link between the till and kitchen displays.
///
/// The till (Full POS mode) runs [KdsServer] on the restaurant's network; each
/// kitchen device (KDS mode) runs a [KdsClient] pointed at the till's address.
/// No internet involved — tickets cross the room, not the world.
///
/// The till stays the single authority over ticket state. The protocol is
/// deliberately tiny and state-based so the two sides can never diverge:
///   server → client  {"type":"snapshot","orders":[...]}   (full board, every change)
///   client → server  {"type":"bump","id":"..."}           (a request, not a mutation)
/// A bump from the kitchen is applied by the till, which then rebroadcasts —
/// so every screen always shows exactly what the till believes.
class KdsServer {
  KdsServer({required this.getSnapshot, required this.onBump});

  /// The current board, serialized. Called when a client connects.
  final List<Map<String, dynamic>> Function() getSnapshot;

  /// A kitchen device asked to advance this ticket.
  final void Function(String id) onBump;

  HttpServer? _http;
  final _clients = <WebSocket>{};

  int get clientCount => _clients.length;
  int? get port => _http?.port;

  Future<void> start({
    int port = KdsLink.defaultPort,
    InternetAddress? bind,
  }) async {
    final server =
        await HttpServer.bind(bind ?? InternetAddress.anyIPv4, port);
    _http = server;
    server.listen((req) async {
      if (!WebSocketTransformer.isUpgradeRequest(req)) {
        req.response
          ..statusCode = HttpStatus.badRequest
          ..close();
        return;
      }
      final ws = await WebSocketTransformer.upgrade(req);
      _clients.add(ws);
      // A display that just connected needs the whole board immediately.
      _send(ws, {'type': 'snapshot', 'orders': getSnapshot()});
      ws.listen(
        (data) {
          try {
            final m = jsonDecode(data as String) as Map<String, dynamic>;
            if (m['type'] == 'bump' && m['id'] is String) {
              onBump(m['id'] as String);
            }
          } catch (_) {
            // A malformed frame from a mismatched version is ignored, never fatal.
          }
        },
        onDone: () => _clients.remove(ws),
        onError: (_) => _clients.remove(ws),
      );
    });
  }

  void broadcast(List<Map<String, dynamic>> orders) {
    final msg = jsonEncode({'type': 'snapshot', 'orders': orders});
    for (final ws in _clients.toList()) {
      try {
        ws.add(msg);
      } catch (_) {
        _clients.remove(ws);
      }
    }
  }

  void _send(WebSocket ws, Map<String, dynamic> m) {
    try {
      ws.add(jsonEncode(m));
    } catch (_) {}
  }

  Future<void> stop() async {
    for (final ws in _clients.toList()) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _clients.clear();
    await _http?.close(force: true);
    _http = null;
  }
}

/// The kitchen-display side: keeps dialling the till until it answers, mirrors
/// every snapshot it receives, and reconnects forever — a kitchen screen must
/// come back by itself after a Wi-Fi blip or a till restart, untouched.
class KdsClient {
  KdsClient({
    required this.address,
    required this.onSnapshot,
    this.onStatus,
    this.retryDelay = const Duration(seconds: 3),
  });

  /// host or host:port of the till.
  final String address;
  final void Function(List<dynamic> rawOrders) onSnapshot;
  final void Function(bool connected)? onStatus;
  final Duration retryDelay;

  WebSocket? _ws;
  bool _closed = false;

  bool get isConnected => _ws != null;

  Future<void> run() async {
    final target =
        address.contains(':') ? address : '$address:${KdsLink.defaultPort}';
    while (!_closed) {
      try {
        final ws = await WebSocket.connect('ws://$target');
        if (_closed) {
          await ws.close();
          return;
        }
        _ws = ws;
        onStatus?.call(true);
        await for (final data in ws) {
          try {
            final m = jsonDecode(data as String) as Map<String, dynamic>;
            if (m['type'] == 'snapshot' && m['orders'] is List) {
              onSnapshot(m['orders'] as List);
            }
          } catch (_) {
            // Skip a bad frame; the next snapshot heals everything.
          }
        }
      } catch (_) {
        // Till unreachable — fall through to the retry wait.
      }
      _ws = null;
      onStatus?.call(false);
      if (_closed) return;
      await Future<void>.delayed(retryDelay);
    }
  }

  /// Ask the till to advance a ticket. Fire-and-forget: the till's rebroadcast
  /// is the confirmation.
  void bump(String id) {
    try {
      _ws?.add(jsonEncode({'type': 'bump', 'id': id}));
    } catch (_) {}
  }

  Future<void> close() async {
    _closed = true;
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
  }
}

abstract final class KdsLink {
  /// One well-known port so a kitchen device only ever needs the till's IP.
  static const int defaultPort = 8765;
}
