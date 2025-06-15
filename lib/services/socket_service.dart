import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(String token) {
    _socket = IO.io('https://stripe.lalit.pro', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      notifyListeners();
      print('Connected to socket server');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      print('Disconnected from socket server');
    });
  }

  void joinTask(int taskId) {
    _socket?.emit('join_task', taskId);
  }

  void editTask(int taskId, String title, String description) {
    _socket?.emit('edit_task', {
      'taskId': taskId,
      'title': title,
      'description': description,
    });
  }

  void onTaskUpdated(Function(Map<String, dynamic>) callback) {
    _socket?.on('task_updated', (data) {
      callback(data);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }
}