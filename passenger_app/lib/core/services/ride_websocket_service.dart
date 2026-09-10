import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class RideWebSocketService {
  WebSocketChannel? _channel;

  void connect({
    required int userId,
    required String token,
    String baseUrl = "http://localhost:8000",
    required void Function(Map<String, dynamic>) onMessage,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) {
    disconnect();

    final wsScheme = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final hostPort = baseUrl.replaceAll(RegExp(r'^https?://'), '');

    final uri = Uri.parse(
      '$wsScheme://$hostPort/notifications/ws/$userId?token=${Uri.encodeComponent(token)}',
    );

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message);

          if (decoded is Map) {
            onMessage(
              Map<String, dynamic>.from(decoded),
            );
          }
        } catch (e) {
          onError?.call(e);
        }
      },
      onError: (error) {
        onError?.call(error);
      },
      onDone: onDone,
      cancelOnError: false,
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
  }
}