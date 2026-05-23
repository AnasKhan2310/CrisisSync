import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onConnected;
  Function(dynamic)? onConnectionError;

  WebSocketService({required this.url});

  bool get isConnected => _isConnected;

  void connect() {
    if (_isConnected) return;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      if (onConnected != null) onConnected!();

      _channel!.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> data = jsonDecode(message);
            if (onMessageReceived != null) {
              onMessageReceived!(data);
            }
          } catch (e) {
            print("Error parsing WebSocket JSON: $e");
          }
        },
        onError: (error) {
          _isConnected = false;
          print("WebSocket Connection Error: $error");
          if (onConnectionError != null) onConnectionError!(error);
          _reconnect();
        },
        onDone: () {
          _isConnected = false;
          print("WebSocket Connection Closed.");
          _reconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      if (onConnectionError != null) onConnectionError!(e);
      _reconnect();
    }
  }

  void sendTrigger(List<Map<String, dynamic>> signals) {
    if (_channel != null && _isConnected) {
      final payload = {
        "type": "trigger",
        "signals": signals,
      };
      _channel!.sink.add(jsonEncode(payload));
    } else {
      print("WebSocket not connected. Cannot send trigger.");
    }
  }

  void _reconnect() {
    Future.delayed(Duration(seconds: 5), () {
      if (!_isConnected) {
        print("Reconnecting to WebSocket...");
        connect();
      }
    });
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _isConnected = false;
    }
  }
}
