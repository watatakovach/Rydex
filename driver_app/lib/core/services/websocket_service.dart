
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/ride.dart';
import 'auth_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  bool _isConnected = false;
  bool _isConnecting = false;

  int? _userId;

  void Function(Ride ride)? _onRideRequest;
  void Function(dynamic error)? _onConnectionError;

  Timer? _reconnectTimer;

  // ============================================================
  // RYDEX BACKEND CONFIGURATION
  // ============================================================

  // Your PC's Wi-Fi IPv4 address.
  //
  // Android phone:
  // ws://192.168.2.105:8000
  //
  // Flutter Web / Edge:
  // ws://127.0.0.1:8000
  //
  // IMPORTANT:
  // The Android phone and PC must be connected to the same Wi-Fi.
  static const String androidHost = '192.168.2.105';
  static const String webHost = '127.0.0.1';

  static const int backendPort = 8000;

  // ============================================================
  // BUILD WEBSOCKET URL
  // ============================================================

  Uri _buildWebSocketUri(int userId, String? token) {
    final host = kIsWeb ? webHost : androidHost;
    final tokenParam = (token != null && token.isNotEmpty)
        ? '?token=${Uri.encodeComponent(token)}'
        : '';

    return Uri.parse(
      'ws://$host:$backendPort/notifications/ws/$userId$tokenParam',
    );
  }

  // ============================================================
  // CONNECT TO RYDEX WEBSOCKET
  //
  // FastAPI endpoint:
  //
  // /notifications/ws/{user_id}
  //
  // Android:
  // ws://192.168.2.105:8000/notifications/ws/{user_id}
  //
  // Edge:
  // ws://127.0.0.1:8000/notifications/ws/{user_id}
  // ============================================================

  Future<void> connect({
    required int userId,
    required void Function(Ride ride) onRideRequest,
    void Function(dynamic error)? onConnectionError,
  }) async {
    // ----------------------------------------------------------
    // SAVE CALLBACKS
    // ----------------------------------------------------------

    _userId = userId;
    _onRideRequest = onRideRequest;
    _onConnectionError = onConnectionError;

    // ----------------------------------------------------------
    // PREVENT DUPLICATE CONNECTIONS
    // ----------------------------------------------------------

    if (_isConnected || _isConnecting) {
      debugPrint(
        'RYDEX WebSocket: Already connected/connecting.',
      );

      return;
    }

    _isConnecting = true;

    // ----------------------------------------------------------
    // CANCEL OLD RECONNECT TIMER
    // ----------------------------------------------------------

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // ----------------------------------------------------------
    // CLOSE OLD CHANNEL
    // ----------------------------------------------------------

    try {
      await _channel?.sink.close();
    } catch (_) {}

    _channel = null;

    // ----------------------------------------------------------
    // BUILD URL
    // ----------------------------------------------------------

    final token = await AuthService.getToken();
    final uri = _buildWebSocketUri(userId, token);

    debugPrint(
      '==================================================',
    );

    debugPrint(
      'RYDEX WebSocket: Connecting...',
    );

    debugPrint(
      'RYDEX WebSocket URL: $uri',
    );

    debugPrint(
      'RYDEX WebSocket User ID: $userId',
    );

    debugPrint(
      'RYDEX WebSocket Platform: '
      '${kIsWeb ? "WEB" : "ANDROID"}',
    );

    debugPrint(
      '==================================================',
    );

    try {
      // --------------------------------------------------------
      // CREATE CHANNEL
      // --------------------------------------------------------

      final channel = WebSocketChannel.connect(uri);

      _channel = channel;

      // --------------------------------------------------------
      // WAIT FOR CONNECTION
      // --------------------------------------------------------

      await channel.ready;

      _isConnected = true;
      _isConnecting = false;

      debugPrint(
        '==================================================',
      );

      debugPrint(
        'RYDEX WebSocket: CONNECTED SUCCESSFULLY',
      );

      debugPrint(
        'RYDEX WebSocket URL: $uri',
      );

      debugPrint(
        '==================================================',
      );

      // --------------------------------------------------------
      // LISTEN FOR SERVER MESSAGES
      // --------------------------------------------------------

      channel.stream.listen(
        _handleMessage,

        onError: (error) {
          debugPrint(
            'RYDEX WebSocket stream error: $error',
          );

          _handleConnectionFailure(error);
        },

        onDone: () {
          debugPrint(
            'RYDEX WebSocket: Connection closed.',
          );

          _isConnected = false;
          _isConnecting = false;

          _scheduleReconnect();
        },

        cancelOnError: false,
      );
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;

      debugPrint(
        '==================================================',
      );

      debugPrint(
        'RYDEX WebSocket CONNECTION FAILED',
      );

      debugPrint(
        'URL: $uri',
      );

      debugPrint(
        'ERROR: $e',
      );

      debugPrint(
        '==================================================',
      );

      _onConnectionError?.call(e);

      _scheduleReconnect();
    }
  }

  // ============================================================
  // HANDLE SERVER MESSAGE
  // ============================================================

  void _handleMessage(dynamic message) {
    try {
      debugPrint(
        'RYDEX WebSocket message: $message',
      );

      final decoded = jsonDecode(
        message.toString(),
      );

      if (decoded is! Map<String, dynamic>) {
        debugPrint(
          'RYDEX WebSocket: Invalid message format.',
        );

        return;
      }

      final type = decoded['type'];

      // ========================================================
      // RIDE REQUEST
      // ========================================================

      if (type == 'ride_request') {
        final rideData = decoded['ride'];

        if (rideData is Map) {
          final ride = Ride.fromJson(
            Map<String, dynamic>.from(
              rideData,
            ),
          );

          debugPrint(
            'RYDEX WebSocket: Ride request received '
            '(ride=${ride.id})',
          );

          _onRideRequest?.call(
            ride,
          );
        }

        return;
      }

      // ========================================================
      // OTHER EVENTS
      // ========================================================

      debugPrint(
        'RYDEX WebSocket: Received event type=$type',
      );
    } catch (e) {
      debugPrint(
        'RYDEX WebSocket message parsing error: $e',
      );

      _onConnectionError?.call(e);
    }
  }

  // ============================================================
  // CONNECTION FAILURE
  // ============================================================

  void _handleConnectionFailure(
    dynamic error,
  ) {
    _isConnected = false;
    _isConnecting = false;

    _onConnectionError?.call(
      error,
    );

    _scheduleReconnect();
  }

  // ============================================================
  // AUTOMATIC RECONNECT
  // ============================================================

  void _scheduleReconnect() {
    // ----------------------------------------------------------
    // Don't reconnect after intentional disconnect.
    // ----------------------------------------------------------

    if (_userId == null) {
      return;
    }

    if (_isConnected || _isConnecting) {
      return;
    }

    if (_reconnectTimer != null &&
        _reconnectTimer!.isActive) {
      return;
    }

    debugPrint(
      'RYDEX WebSocket: Reconnecting in 5 seconds...',
    );

    _reconnectTimer = Timer(
      const Duration(seconds: 5),
      () {
        final userId = _userId;

        final rideCallback = _onRideRequest;

        if (userId == null ||
            rideCallback == null) {
          return;
        }

        connect(
          userId: userId,
          onRideRequest: rideCallback,
          onConnectionError: _onConnectionError,
        );
      },
    );
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  void sendMessage(
    Map<String, dynamic> message,
  ) {
    if (!_isConnected ||
        _channel == null) {
      debugPrint(
        'RYDEX WebSocket: Cannot send message. '
        'Not connected.',
      );

      return;
    }

    try {
      _channel!.sink.add(
        jsonEncode(
          message,
        ),
      );

      debugPrint(
        'RYDEX WebSocket: Message sent.',
      );
    } catch (e) {
      debugPrint(
        'RYDEX WebSocket send error: $e',
      );
    }
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  Future<void> disconnect() async {
    debugPrint(
      'RYDEX WebSocket: Disconnecting...',
    );

    // ----------------------------------------------------------
    // Prevent automatic reconnect.
    // ----------------------------------------------------------

    _userId = null;

    _onRideRequest = null;
    _onConnectionError = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _isConnected = false;
    _isConnecting = false;

    try {
      await _channel?.sink.close();
    } catch (_) {}

    _channel = null;
  }

  // ============================================================
  // CONNECTION STATUS
  // ============================================================

  bool get isConnected => _isConnected;

  bool get isConnecting => _isConnecting;
}
