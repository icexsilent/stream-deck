import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models.dart';

enum LinkState { connecting, connected, searching, badToken }

class PressResult {
  final String id;
  final String? error;
  PressResult(this.id, this.error);
}

/// Keeps one WebSocket to the PC alive: reconnects on drop, and after repeated failures looks the PC up via mDNS in case its IP changed.
class DeckConnection extends ChangeNotifier {
  Pairing pairing;
  LinkState state = LinkState.connecting;
  DeckConfig? config;
  final results = StreamController<PressResult>.broadcast();

  WebSocketChannel? _ch;
  Timer? _retry, _ping, _pongWait;
  Completer<String?>? _saving;
  int _failures = 0;
  bool _disposed = false;

  DeckConnection(this.pairing) {
    _connect();
  }

  static const _prefsKey = 'pairing';
  static Future<Pairing?> loadSaved() async => Pairing.parse((await SharedPreferences.getInstance()).getString(_prefsKey) ?? '');
  static Future<void> save(Pairing p) async => (await SharedPreferences.getInstance()).setString(_prefsKey, p.toString());
  static Future<void> forget() async => (await SharedPreferences.getInstance()).remove(_prefsKey);

  Future<WebSocketChannel?> _open(String host) async {
    final ch = WebSocketChannel.connect(Uri(scheme: 'ws', host: host, port: pairing.port, queryParameters: {'t': pairing.token}));
    try {
      await ch.ready.timeout(const Duration(seconds: 4));
      return ch;
    } catch (_) {
      ch.sink.close();
      return null;
    }
  }

  Future<void> _connect() async {
    if (_disposed) return;
    _set(_failures >= 2 ? LinkState.searching : LinkState.connecting);
    var ch = await _open(pairing.host);
    if (ch == null && _failures >= 2) {
      for (final ip in await _discover()) {
        if (ip == pairing.host) continue;
        ch = await _open(ip);
        if (ch != null) {
          pairing = pairing.withHost(ip);
          await save(pairing);
          break;
        }
      }
    }
    if (_disposed) return ch?.sink.close();
    final open = ch;
    if (open == null) return _scheduleRetry();
    _ch = open;
    open.stream.listen(_onMessage, onDone: () => _onClosed(open), onError: (_) {});
    _ping = Timer.periodic(const Duration(seconds: 10), (_) {
      _send({'type': 'ping'});
      // Wi-Fi drops are often silent; no pong means the socket is dead even if it looks open.
      _pongWait ??= Timer(const Duration(seconds: 5), () => open.sink.close());
    });
  }

  Future<List<String>> _discover() async {
    try {
      final d = await startDiscovery('_streamdeck._tcp', ipLookupType: IpLookupType.v4);
      await Future.delayed(const Duration(seconds: 4));
      await stopDiscovery(d);
      return [for (final s in d.services) for (final a in s.addresses ?? const []) a.address];
    } catch (_) {
      return [];
    }
  }

  void _onMessage(dynamic data) {
    final msg = jsonDecode(data as String) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'config':
        config = DeckConfig.fromJson(msg['config']);
        _failures = 0;
        _set(LinkState.connected);
      case 'pong':
        _pongWait?.cancel();
        _pongWait = null;
      case 'ok':
        results.add(PressResult(msg['id'], null));
      case 'saved':
        _saving?.complete(null);
        _saving = null;
      case 'error':
        if (msg['id'] != null) {
          results.add(PressResult(msg['id'], msg['error']));
        } else {
          _saving?.complete(msg['error']);
          _saving = null;
        }
    }
  }

  void _onClosed(WebSocketChannel ch) {
    if (ch != _ch) return;
    _ch = null;
    _ping?.cancel();
    _pongWait?.cancel();
    _pongWait = null;
    _saving?.complete('conexão caiu antes de salvar');
    _saving = null;
    if (ch.closeCode == 4001) return _set(LinkState.badToken);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _failures++;
    _set(_failures >= 2 ? LinkState.searching : LinkState.connecting);
    _retry = Timer(Duration(seconds: _failures < 3 ? 1 : 3), _connect);
  }

  /// Forces an immediate retry, e.g. when the app returns to the foreground.
  void reconnectNow() {
    if (_ch != null || state == LinkState.badToken) return;
    _retry?.cancel();
    _connect();
  }

  void _send(Map<String, dynamic> msg) => _ch?.sink.add(jsonEncode(msg));

  void press(String id) => _send({'type': 'press', 'id': id});

  /// Returns null on success or the agent's error message.
  Future<String?> saveConfig(DeckConfig c) {
    if (_ch == null) return Future.value('sem conexão com o PC');
    _saving = Completer<String?>();
    _send({'type': 'save', 'config': c.toJson()});
    return _saving!.future.timeout(const Duration(seconds: 5), onTimeout: () => 'o PC não respondeu');
  }

  void _set(LinkState s) {
    if (_disposed) return;
    state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _ping?.cancel();
    _pongWait?.cancel();
    _ch?.sink.close();
    results.close();
    super.dispose();
  }
}
