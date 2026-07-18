import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/debug_log.dart';
import 'api_client.dart';

typedef RealtimeHandler = void Function(Map<String, dynamic> event);

class RealtimeService {
  RealtimeService(this.client);
  final ApiClient client;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnect;
  Timer? _ping;
  RealtimeHandler? onEvent;
  bool _manualClose = false;

  void connect() {
    _manualClose = false;
    _reconnect?.cancel();
    final token = client.accessToken;
    if (token == null || token.isEmpty) return;
    final uri = Uri.parse(
      '${ApiClient.baseUrl.replaceFirst('https', 'wss').replaceFirst('http', 'ws')}/ws?token=$token',
    );
    try {
      _channel?.sink.close();
    } catch (_) {}
    AppLog.i('ws connect', scope: 'realtime');
    _channel = WebSocketChannel.connect(uri);
    _sub?.cancel();
    _sub = _channel!.stream.listen(
      (raw) {
        try {
          final text = raw is String ? raw : utf8.decode(raw as List<int>);
          final data = jsonDecode(text);
          if (data is Map) {
            onEvent?.call(Map<String, dynamic>.from(data));
          }
        } catch (e) {
          AppLog.w('ws parse failed', scope: 'realtime', data: e);
        }
      },
      onDone: _scheduleReconnect,
      onError: (e) {
        AppLog.w('ws error', scope: 'realtime', data: e);
        _scheduleReconnect();
      },
    );
    _ping?.cancel();
    _ping = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      } catch (_) {}
    });
  }

  void _scheduleReconnect() {
    if (_manualClose) return;
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 3), connect);
  }

  void disconnect() {
    _manualClose = true;
    _reconnect?.cancel();
    _ping?.cancel();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
