

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_client/web_socket_client.dart';

class ChatWebService {
  static final _instance = ChatWebService._internal();
  WebSocket? _socket;

  factory ChatWebService() => _instance;

  ChatWebService._internal();
  final _searchResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _contentController = StreamController<Map<String, dynamic>>.broadcast(); 

  Stream<Map<String, dynamic>> get searchResultStream =>
      _searchResultController.stream;
  Stream<Map<String, dynamic>> get contentStream => _contentController.stream;

  void connect() {
    _socket = WebSocket(Uri.parse("ws://localhost:8000/ws/chat"));

    _socket!.messages.listen((message) {
      print("Received WebSocket message: $message");
      final data = json.decode(message);

      if (data['type'] == 'search_result') {
        _searchResultController.add(data);

        if (data['data'] is List) {
          for (var item in data['data']) {
            if (item is Map && item.containsKey('content') && item['content'] != null) {
              _contentController.add({'data': item['content']});
            }
          }
        }
      } else if (data['type'] == 'answer_chunk') {
        _contentController.add(data);
      } else {
        print("Received unknown message type: ${data['type']}");
      }
    });
  }

  void chat(String query) {
    print(query);
    print(_socket);
    if (_socket != null) {
      _socket!.send(json.encode({'query': query}));
    }
  }


  void dispose() {
    _searchResultController.close();
    _contentController.close();
    _socket?.close();
  }
}


